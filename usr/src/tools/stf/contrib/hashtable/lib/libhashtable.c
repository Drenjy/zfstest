/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or http://www.opensolaris.org/os/licensing.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */

/*
 * Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 */

#include <errno.h>
#include <limits.h>
#include <note.h>
#include <stdlib.h>
#include <strings.h>
#include <synch.h>

#include <hashtable.h>

#include "hashtable_data.h"

/* LINTLIBRARY */

/*
 * static int
 * ht_counter_init(hashtable_counter_t *counter);
 *
 * Description:
 *	Initialize a hashtable statistic counter.
 *
 * Parameters:
 *	hashtable_counter_t *counter
 *		Input/Output - A pointer to a counter to be intialized.
 *
 * Return value:
 *	int	Upon successful initialization of the counter value and its
 *		associated lock a zero value will be returned. If the lock
 *		could not be initialized, then the return value from lock
 *		initialization will be returned (See mutex_init for details).
 */
static int
ht_counter_init(hashtable_counter_t *counter)
{
	counter->value	= 0;
	return (mutex_init(&counter->mutex, USYNC_THREAD, NULL));

} /* static int ht_counter_init(hashtable_counter_t *counter) {...} */

/*
 * static int
 * ht_counter_add(hashtable_counter_t *counter, longlong_t delta);
 *
 * Description:
 *	Sum the delta to the counter value atomically.
 *
 * Parameters:
 *	hashtable_counter_t *counter
 *		Input/Output - A pointer to a counter to be adjusted by the
 *		value of the delta passed.
 *
 *	longlong_t delta
 *		Input - Amount by which to adjust the counter value.
 *
 * Return value:
 *	int	If the lock could be obtained, then zero will be returned.
 *		If the lock could not be fetched, then a non-zero value will
 *		be returned and errno will be set.
 */
static int
ht_counter_add(hashtable_counter_t *counter, longlong_t delta)
{
	/*
	 * Fetch the lock first.
	 */
	if (errno = mutex_lock(&counter->mutex)) {
		return (-2);

	} /* if (errno = mutex_lock(&counter->mutex)) {...} */

	/*
	 * Increment the value.
	 */
	counter->value += delta;

	/*
	 * Give up the lock.
	 */
	if (errno = mutex_unlock(&counter->mutex)) {
		return (-2);

	} /* if (errno = mutex_unlock(&counter->mutex)) {...} */

	/*
	 * All done, and it worked...
	 */
	return (0);

} /* int ht_counter_add(... *counter, longlong_t delta) {...} */

/*
 * static int
 * ht_average_init(hashtable_average_t *average);
 *
 * Description:
 *	Initialize a hashtable average structure.
 *
 * Parameters:
 *	hashtable_average_t *average
 *		Input/Output - A pointer to an average structure to be
 *		initialized.
 *
 * Return value:
 *	int	Upon successully setting the values for the average and
 *		initializing the lock a zero value will be returned. If the
 *		lock could not be intialized, the the error value from lock
 *		initialization will be returned (See mutex_init for details).
 */
static int
ht_average_init(hashtable_average_t *average)
{
	average->count		=
	    average->sum	=
	    average->current	=
	    average->maximum	= 0;

	return (mutex_init(&average->mutex, USYNC_THREAD, NULL));

} /* static int ht_average_init(hashtable_average_t *average) {...} */

/*
 * static int
 * ht_average_update(hashtable_average_t *average, current);
 *
 * Description:
 *	Update the values used for computing averages.
 *
 * Parameters:
 *	hashtable_average_t *average
 *		Input/Output - A pointer to an average structure to be updated
 *		with the current value passed.
 *
 *	longlong_t count
 *		Input - Count to be added to the average count.
 *
 *	longlong_t sum
 *		Input - Sum to be added to the average sum.
 *
 *	longlogn_t current
 *		Input - Current value to be stored in average.
 *
 *	longlong_t maximum
 *		Input - The larger of this paramater value, the maximum
 *		in the average, and the current will be stored in the
 *		average.
 *
 * Return value
 *	int	If the lock could be obtained, then zero will be returned. If
 *		the lock could not be obtained, then a non-zero value will be
 *		returned.
 */
static int
ht_average_update(hashtable_average_t *average,
    longlong_t count,
    longlong_t sum,
    longlong_t current,
    longlong_t maximum)
{
	/*
	 * Fetch the lock...
	 */
	if (mutex_lock(&average->mutex)) {
		return (-2);

	} /* if (mutex_lock(&average->mutex)) {...} */

	/*
	 * Stash the current value, check for a maximum, increment the count,
	 * and increase the sum by current.
	 */
	average->current = current;
	average->count	+= count;
	average->sum	+= sum;
	if (maximum > average->maximum) {
		average->maximum = maximum;

	} /* if (maximum > average->maximum) {...} */
	if (current > average->maximum) {
		average->maximum = current;

	} /* if (current > average->maximum) {...} */

	/*
	 * Give back the lock and blow!
	 */
	if (mutex_unlock(&average->mutex)) {
		return (-2);

	} /* if (mutex_unlock(average->mutex)) {...} */

	/*
	 * All done, and it seemed to work.
	 */
	return (0);

} /* int ht_average_update(hashtable_average_t *average, current) {...} */

/*
 * static int
 * ht_average_increment(hashtable_average_t *average, current);
 *
 * Description:
 *	Increment the counter in the average and increase the sum by the
 *	current value passed.
 *
 * Parameters:
 *	hashtable_average_t *average
 *		Input/Output - Pointer to the average structure to be updated.
 *
 *	longlong_t current
 *		Input - Current value to be added to the average.
 *
 * Return value:
 *	int	If the lock could be fetched, then zero will be returned. If
 *		the lock could not be fetched, then a non-zero value will be
 *		returned and errno will be set.
 */
static int
ht_average_increment(hashtable_average_t *average, longlong_t current)
{
	/*
	 * Fetch the lock...
	 */
	if (mutex_lock(&average->mutex)) {
		return (-2);

	} /* if (mutex_lock(&average->mutex)) {...} */

	/*
	 * Save the current, increment the count, add the sum, and check
	 * the maximum.
	 */
	average->current = current;
	++average->count;
	average->sum	+= current;
	if (current > average->maximum) {
		average->maximum = current;

	} /* if (current > average->maximum) {...} */

	/*
	 * Give back the lock and blow!
	 */
	if (mutex_unlock(&average->mutex)) {
		return (-2);

	} /* if (mutex_unlock(average->mutex)) {...} */

	/*
	 * All done, and it seemed to work.
	 */
	return (0);


} /* int ht_average_increment(... *average, longlong_t current) {...} */

/*
 * int
 * ht_evaluate_threshold_default(size_t numents,
 *	u_longlong_t depthcount,
 *	u_longlong_t depthsum,
 *	u_longlong_t searchcount.
 *	u_longlong_t searchsum);
 *
 * Description
 *	A default function for evaluating whether or not a table needs to be
 *	resized due to inordinant searches of some depth. This default function
 *	alway answers false.
 *
 * Parameters:
 * 	size_t numents
 *		Input - Size of the current table. This is the mod value used
 *		in computing the hash index.
 *
 *	u_longlong_t depthcount
 *		Input - Count of the number of times the depth has been
 *		updated.
 *
 *	u_longlong_t depthsum
 *		Input - Sum of all the depth values.
 *
 *	u_longlong_t searchcount
 *		Input - Count of the number of times a chain was searched for
 *		an key.
 *
 *	u_longlong_t searchdepth
 *		Input - Sum of the depths searched.
 *
 * Return value:
 *	int	If the table should be resized, then a non-zero value will be
 *		returned. If the table should not be resized, then zero will
 *		be returned.
 */
int
ht_evaluate_threshold_default(size_t numents,
    u_longlong_t depthcount,
    u_longlong_t depthsum,
    u_longlong_t searchcount,
    u_longlong_t searchsum)
{
	if (numents	!= 0 &&
	    depthcount	!= 0 &&
	    depthsum	!= 0 &&
	    searchcount	!= 0 &&
	    searchsum	!= 0) {

		return (0 == 1);

	} else {

		return (1 == 0);

	}

} /* int ht_evaluate_threshold_default(...) {...} */

/*
 *
 *  static int
 *  ht_init_entries(hashtable_entry_t *hte, size_t numents)
 *
 *  Description:
 *	Initialize all of the entries in the table passed.
 *
 *  Parameters:
 *	hashtable_entry_t *hte
 *		Input/Output - A pointer to the table of entries to be
 *		initialized.
 *
 *	size_t numents
 *		Input - A count of the entries in the table.
 *
 *  Return value:
 *	int	If all entries are initialized without error, then zero (0)
 *		will be retured. If initialization fails (as in rwlock_init()),
 *		then non-zero will be returned indicating the number of
 *		entries with errors, and errno will be set.
 */
static int
ht_init_entries(hashtable_entry_t *hte, size_t numents)
{
	/*
	 * Locals...
	 */
	int	ret	= 0;	/* Just a return value.			*/
	int	result	= 0;	/* Result from this function.		*/

	/*
	 * Simple, loop through all the entries, setting all the fields
	 * to usable values and initialize the rwlocks.
	 */
	for (; numents--; ++hte) {
		hte->next	= (hashtable_entry_t *)NULL;
		hte->flags	= (hashtable_entry_flag_t)NULL;
		hte->key	=
		    hte->data	= (void *)NULL;

		if (! (hte->flags & htef_lock_initialized)) {

			ret = rwlock_init(&hte->rwlock,
			    USYNC_THREAD,
			    (void *)NULL);

			if (ret == 0) {
				hte->flags |= htef_lock_initialized;

			} else {
				++result;
				errno	= ret;

			} /* if (ret != 0) {...} */

		} /* if (! (hte->flags & htef_lock_initialized) {...} */

	} /* for (; numents--; ++hte) {...} */

	/*
	 * Guess it all worked.
	 */
	return (result);

} /* int ht_init_entries(hashtable_entry_t *hte, ...) {...} */

/*
 *
 *  static int
 *  ht_destroy_entries(hashtable_entry_t *hte, size_t numents)
 *
 *  Description:
 *	Destroy all of the entries in the table passed.
 *
 *  Parameters:
 *	hashtable_entry_t *hte
 *		Input/Output - A pointer to the table of entries to be
 *		destroyed.
 *
 *	size_t numents
 *		Input - A count of the entries in the table.
 *
 *  Return value:
 *	int	If all entries are destroyed without error, then zero (0)
 *		will be retured. If destruction fails (as in rwlock_destroy()),
 *		then non-zero will be returned indicating the number of
 *		entries with errors, and errno will be set.
 */
static int
ht_destroy_entries(hashtable_entry_t *hte, size_t numents)
{
	/*
	 * Locals...
	 */
	int	ret	= 0;	/* Just a return value.			*/
	int	result	= 0;	/* Result from this function.		*/

	/*
	 * Simple, loop through all the entries, setting all the fields
	 * to unusable values and destroy the rwlocks.
	 */
	for (; numents--; ++hte) {
		hte->flags	&= ~htef_occupied;
		hte->next	 = (struct hashtable_entry *)NULL;
		hte->key	 = (void *)NULL;
		hte->data	 = (void *)NULL;

		if ((hte->flags & htef_lock_initialized) &&
		    ((ret = rwlock_destroy(&hte->rwlock)) == 0)) {

			hte->flags &= ~htef_lock_initialized;

		} else {
			++result;
			errno	= ret;

		} /* if ((...rwlock_destroy(...)) == 0) {...} else {...} */

	} /* for (; numents--; ++hte) {...} */

	/*
	 * Guess it all worked.
	 */
	return (result);

} /* int ht_destroy_entries(hashtable_entry_t *hte, ...) {...} */

/*
 *
 *  static hashtable_slab_t *
 *  ht_create_slab(size_t numents);
 *
 *  Description:
 *	Allocate and initialize a slab of hash table entries.
 *
 *  Parameters:
 *	size_t numents
 *		Input - Number of entries needed in the slab.
 *
 *  Return value:
 *	hashtable_slab_t * If allocation and initialization succeeds, the the
 *		address of of the slab will be returned. If allocation fails or
 *		initialization of the entries fails, NULL will be returned and
 *		errno will be set.
 *
 */
static hashtable_slab_t *
ht_create_slab(size_t numents)
{
	/*
	 * Locals...
	 */
	hashtable_slab_t	*slab;	/* @ of slab allocated.		*/

	/*
	 * Don't get bamboozled by a zero entry slab.
	 */
	if (! numents > 0) {
		errno = EINVAL;
		return ((hashtable_slab_t *)NULL);

	} /* if (! numents > 0) {...} */

	/*
	 * Allocate enough room for numents entries plus the size of the slab
	 * header structure.
	 */
	slab = (hashtable_slab_t *)malloc(sizeof (*slab) +
	    numents * sizeof (*slab->header.entry));

	if (slab == (hashtable_slab_t *)NULL) {
		return (slab);

	} /* if (slab == (hashtable_slab_t *)NULL) {...} */

	/*
	 * Point to the first entry in the slab. It's immediately following
	 * the slab header itself.
	 */
	slab->header.entry	= (hashtable_entry_t *)&slab[1];
	slab->header.entrycount	= numents;

	/*
	 *  Initialize every entry in the table.
	 */
	if (ht_init_entries(slab->header.entry, slab->header.entrycount)) {
		(void) free(slab);
		return ((hashtable_slab_t *)NULL);

	} /* if (ht_init_entries(...)) {...} */

	/*
	 * All done...
	 */
	return (slab);

} /* hashtable_slab_t *ht_create_slab(size_t numents) {...} */

/*
 *
 *  static int
 *  ht_destroy_slab(hashtable_slab_t *slab);
 *
 *  Description:
 *	Allocate and initialize a slab of hash table entries.
 *
 *  Parameters:
 *	hashtable_slab_t *slab
 *		Input - The slab to destroy.
 *
 *  Return value:
 *	int	Upon successful destruction of the slab zero (0) will be
 *		returned. If destruction fails for some reason, then a non-zero
 *		value will be returned and errno will be set.
 *
 */
static int
ht_destroy_slab(hashtable_slab_t *slab)
{
	/*
	 * Locals...
	 */
	int	ret;	/* Just a return value.				*/

	/*
	 * First, destroy all of the entries.
	 */
	ret = ht_destroy_entries(slab->header.entry, slab->header.entrycount);
	if (ret != 0) {
		return (ret);

	} /* if (ht_destroy_entries(...)) {...} */

	/*
	 * Free up the memory for the slab itself.
	 */
	slab->header.next	= (hashtable_slab_t *)NULL;
	slab->header.entry	= (hashtable_entry_t *)NULL;
	slab->header.entrycount	= 0;
	(void) free(slab);

	/*
	 * All done...
	 */
	return (0);

} /* hashtable_slab_t *ht_destroy_slab(hashtable_slab_t *slab) {...} */

/*
 *
 *  unsigned int
 *  ht_hash_compute(void *key, size_t keysize)
 *
 *  Description:
 *	Compute a hash value based on the bytes passed as the key.
 *
 *  Paramaters:
 *
 *  Return value:
 *
 */
size_t
ht_hash_bytes(void *key, size_t keysize, size_t table_size)
{
	/*
	 * Locals...
	 */
	size_t		hash_value;	/* Value to return.	*/
	unsigned char  *sample;		/* Sample of the key.	*/

	/*
	 * Loop through the bytes passed, computing a numeric index to use
	 * in the hash table itself.
	 */
	sample		= (unsigned char *)key;
	for (hash_value = 0; keysize > 0; --keysize) {
		hash_value	<<= 1;
		hash_value	 ^= (size_t)*sample++;

	} /* for ((hash_value = 0, ...) {...} */

	/*
	 * Mod this off to fit the table size.
	 */
	hash_value %= table_size;

	/*
	 * Done.
	 */
	return (hash_value);

} /* unsigned int hash_compute(void *key) */

/*
 *
 *  hashtable_t *
 *  ht_create(size_t numents, size_t keysize, unsigned int options);
 *
 *  Description:
 *	Allocate sufficient memory for a hash table with numents entries.
 *
 *  Paramaters:
 *	size_t numents
 *		Input - Specifies the number of entries expected in the table
 *		when it's full. Room will be allocated for this many entries
 *		during table creation.
 *
 *	int keysize
 *		Input - Specifies the number of bytes in the key for table
 *		entries.
 *
 *	unsigned int options
 *		Input - Options for table mainteance. See the definition for
 *		ht_option_t in hashtable.h for details.
 *
 *  Return value:
 *	hashtable_t * If a table head and entries were successfully allocated,
 *		then the address of the table head is returned. If any failures
 *		occur, then NULL will be returned.
 *
 */
void *
ht_create(size_t numents, size_t keysize, ht_option_t options)
{
	/*
	 * Locals...
	 */
	hashtable_t	*ht;	/* Hash table being created.		*/

	/*
	 * Don't get bamboozled by a zero entry table.
	 */
	if (! numents > 0) {
		errno = EINVAL;
		return ((hashtable_slab_t *)NULL);

	} /* if (! numents > 0) {...} */

	/*
	 *  Allocate the table head, save the options and keysize.
	 */
	ht = (hashtable_t *)malloc(sizeof (*ht));
	if (ht == (hashtable_t *)NULL) {
		return ((void *)ht);

	} /* if ((void *)ht == (void *)NULL) {...} */
	ht->keysize		= keysize;
	ht->options		= options;
	ht->threshold_evaluate	= ht_evaluate_threshold_default;
	ht->hash_compute	= ht_hash_bytes;
	ht->key_compare		= bcmp;
	ht->freechain		= (hashtable_entry_t *)NULL;

	/*
	 * Start the stats collection...
	 */
	if (ht_average_init(&ht->stats.depth)	  ||
	    ht_average_init(&ht->stats.freechain) ||
	    ht_average_init(&ht->stats.searches)) {
		(void) free(ht);
		return ((void *)NULL);

	} /* if (ht_average_init(&ht->depth) || ...) {...} */

	if (ht_counter_init(&ht->stats.deletes)	  ||
	    ht_counter_init(&ht->stats.errors)	  ||
	    ht_counter_init(&ht->stats.hits)	  ||
	    ht_counter_init(&ht->stats.inserts)	  ||
	    ht_counter_init(&ht->stats.probes)	  ||
	    ht_counter_init(&ht->stats.resizes)	  ||
	    ht_counter_init(&ht->stats.slabs)) {
		(void) free(ht);
		return ((void *)NULL);

	} /* if (ht_counter_init(&ht->deletes) || ...) {...} */

	/*
	 * Initialize the locks for the table and the free chain.
	 */
	if (rwlock_init(&ht->tablelock, USYNC_THREAD, NULL)) {
		(void) free(ht);
		return ((void *)NULL);

	} /* if (rwlock_init(&ht->tablelock, USYNC_THREAD, NULL)) {...} */

	if (rwlock_init(&ht->freelock, USYNC_THREAD, NULL)) {
		(void) free(ht);
		return ((void *)NULL);

	} /* if (rwlock_init(&ht->freelock, USYNC_THREAD, NULL)) {...} */

	if (mutex_init(&ht->resizemutex, USYNC_THREAD, NULL)) {
		(void) free(ht);
		return ((void *)NULL);

	} /* if (mutex_init(&...resizemutex, USYNC_THREAD, NULL)) {...} */

	/*
	 * Allocate a slab with enough room for numents entries. The first
	 * slab is also the table (until a resize).
	 */
	ht->slabs = ht_create_slab(numents);
	ht->table = ht->slabs;

	if (ht->table != (hashtable_slab_t *)NULL) {
		(void) ht_counter_add(&ht->stats.slabs, 1);

	} else /* if (ht->table == (hashtable_slab_t *)NULL) */ {
		(void) free(ht);
		return ((void *)NULL);

	} /* if (ht->table != (hashtable_entry_t *)NULL) {...} else {...} */

	/*
	 * Guess it all worked.
	 */
	return ((void *)ht);

} /* hashtable_t *ht_create(int numents, unsigned int options) {...} */

/*
 * static int
 * ht_sweep(hashtable_t *ht);
 *
 * Description:
 *	Sweep a hash table of all references. This only guarantees that no one
 *	was holding any locks for a period. ht->table must be made unavailable
 *	to others before calling ht_sweep(). Otherwise someone else may follow
 *	the broom through the table and no guarantees can be made that the
 *	table is free of leaseholders.
 *
 * Parameters:
 *	hashtable_t *ht
 *		Input - Pointer to a hash table head which has been made
 *		unavailable to anyone else before this call.
 *
 * Return value:
 *	int	If all locks could be held temporarily, then a zero value will
 *		be returned. If any of the locks fails, a non-zero value as
 *		returned from rw_*lock() will be returned.
 *
 */
static int
ht_sweep(hashtable_t *ht)
{

	/*
	 * Locals...
	 */
	hashtable_entry_t	*hte;	/* Pointer to a single entry.	*/
	hashtable_entry_t	*chte;	/* Pointer to a chained entry.	*/
	hashtable_entry_t	*ehte;	/* Pointer to end of the table.	*/
	int			ret;	/* Just a return value.		*/

	/*
	 * To sweep any stale pointers of the table the following sequence
	 * must be followed:
	 *
	 * 1 -	The head must be write locked momentarily to ensure that noone
	 *	still has a read lock on it. This will gaurantee that the only
	 *	stale pointers will be of table entries since the lock on the
	 *	table head is only released after an entry of interest in the
	 *	table has been locked in some fashion.
	 *
	 * 2 -	Every entry in the table must be write locked momentarily
	 *	following the same sequence as a table probe. This will sweep
	 *	any remaining stale pointers of the old table, because to
	 *	have gotten each lock means no other thread has ANY locks on
	 *	entries. There will be no more stale pointers into the old
	 *	table.
	 *
	 * This algorhythm only works if the table is no longer accessible to
	 * any thread outside of the one calling this routine.
	 */

	/*
	 * Lock the table head.
	 */
	if (ret = rw_wrlock(&ht->tablelock)) {

		/*
		 * Ugh! I couldn't even get the first lock!
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);
		return (ret);

	} /* if (rw_wrlock(&ht->tablelock)) {...} */

	if (ret = rw_unlock(&ht->tablelock)) {

		/*
		 * Ditto.
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);
		return (ret);

	} /* if (rw_unlock(&ht->tablelock)) {...} */

	/*
	 * Time to sweep the table. Fetch write locks on EVERY entry for a
	 * bit following the chains... The order through the table itself is
	 * important.
	 */
	ehte = &ht->table->header.entry[ht->table->header.entrycount - 1];
	for (hte = ht->table->header.entry; hte <= ehte; ++hte) {

		/*
		 * Get the write lock on this entry.
		 */
		if ((hte->flags & htef_lock_initialized) &&
		    (ret = rw_wrlock(&hte->rwlock))) {

			/*
			 * Crap! This is a bad place to bail!
			 */
			(void) ht_counter_add(&ht->stats.errors, 1);
			return (ret);

		} /* if (rw_wrlock(&hte->rwlock)) {...} */

		if ((hte->flags & htef_lock_initialized) &&
		    (ret = rw_unlock(&hte->rwlock))) {

			/*
			 * I can't quit now!
			 */
			(void) ht_counter_add(&ht->stats.errors, 1);
			return (ret);

		} /* if (rw_unlock(&hte->rwlock)) {...} */

		/*
		 * Walk the chain and do the same...
		 */
		chte = hte;
		while ((chte = chte->next) != (hashtable_entry_t *)NULL) {

			/*
			 * Get the write lock on this entry.
			 */
			if ((hte->flags & htef_lock_initialized) &&
			    (ret = rw_wrlock(&chte->rwlock))) {

				/*
				 * Crap! I can't quit here!
				 */
				(void) ht_counter_add(&ht->stats.errors, 1);
				return (ret);

			} /* if (rw_wrlock(&chte->rwlock)) {...} */

			if ((hte->flags & htef_lock_initialized) &&
			    (ret = rw_unlock(&hte->rwlock))) {

				/*
				 * Again, I don't dare stop now!
				 */
				(void) ht_counter_add(&ht->stats.errors, 1);
				return (ret);

			} /* if (rw_unlock(&hte->rwlock)) {...} */

		} /* while ((chte  = hte->next) != (... *)NULL) {...} */

	} /* for (; hte != ht->table->header.entry; --hte) {...} */

	/*
	 * The sweep worked!
	 */
	return (ret);

} /* int ht_sweep(hashtable_t *ht) {...} */

/*
 *
 *  void
 *  ht_destroy(hashtable_t *Eht);
 *
 *  Description:
 *	Free all the memory used by a hash table.
 *
 *  Paramaters:
 *	hashtable_t *Eht
 *		Input - Pointer to the hash table to destroy.
 *
 *  Return value:
 *	int	If no errors occur, then zero will be returned. If errors occur
 *		while destroying table entries, then a positive value
 *		indicating the number of entries with errors will be returned
 *		and errno will be set. If errors occurs destroying the rwlocks
 *		in the table, then a negative value will be returned and errno
 *		will be set.
 */
int
ht_destroy(void *Eht)
{
	/*
	 * Locals...
	 */
	hashtable_t		*ht = (hashtable_t *)Eht;
	hashtable_slab_t	*hts;	/* Pointer to a slab.		*/
	int			 ret;	/* Just a return value.		*/

	/*
	 * Destroy the lock in each entry, then the lock for the table.
	 */
	if (errno = rw_wrlock(&ht->tablelock)) {
		/*
		 * We're screwed. There should be a lock here!
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);
		return (-2);

	} /* if (rw_wrlock(&ht->tablelock)) {...} */

	/*
	 * If there are "old" tables hanging around, try to destroy them first.
	 */
	if ((ht->old != (hashtable_t *)NULL) &&
	    ((ret = ht_destroy(ht->old)) != 0)) {

		/*
		 * Well, that didn't seem to work. Leave the old stuff around
		 * and bail!
		 */
		(void) rw_unlock(&ht->tablelock);
		return (ret);

	} /* if (ht->old != (hashtable_t *)NULL) {...} */

	/*
	 * No more old tables...
	 */
	ht->old = (hashtable_t *)NULL;

	/*
	 * Destroy all the slabs.
	 */
	while ((hts = ht->slabs) != (hashtable_slab_t *)NULL) {

		ht->slabs = ht->slabs->header.next;

		if (ret = ht_destroy_slab(hts)) {
			/*
			 * Put hts back on the slab chain so the memory doesn't
			 * leak.
			 */
			hts->header.next	= ht->slabs;
			ht->slabs		= hts;
			(void) ht_counter_add(&ht->stats.errors, 1);
			(void) rw_unlock(&ht->tablelock);
			return (ret);

		} /* if (ht_destroy_slab(hts)) {...} */

		/*
		 * If this slab is also the table, then clear the table
		 * pointer.
		 */
		if (ht->table == hts) {
			ht->table = (hashtable_slab_t *)NULL;

		} /* if (ht->table == hts) {...} */

	} /* while ((hts = ht->header.slabs) != (... *)NULL) {...} */

	/*
	 * Destroy all the locks, except the table lock itself.
	 */
	errno = 0;
	if (ret = mutex_destroy(&ht->stats.probes.mutex)) {
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (mutex_destroy(&...mutex)) {...} */

	if (ret = mutex_destroy(&ht->stats.hits.mutex)) {
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (mutex_destroy(&...hits.mutex)) {...} */

	if (ret = mutex_destroy(&ht->stats.searches.mutex)) {
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (mutex_destroy(&...searches.mutex)) {...} */

	if (ret = mutex_destroy(&ht->stats.resizes.mutex)) {
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (mutex_destroy(&...resizes.mutex)) {...} */

	if (ret = mutex_destroy(&ht->stats.inserts.mutex)) {
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (mutex_destroy(&h...inserts.mutex)) {...} */

	if (ret = mutex_destroy(&ht->stats.deletes.mutex)) {
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (mutex_destroy(&...deletes.mutex)) {...} */

	if (ret = mutex_destroy(&ht->stats.depth.mutex)) {
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (mutex_destroy(&..s.depth.mutex)) {...} */

	if (ret = mutex_destroy(&ht->stats.freechain.mutex)) {
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (mutex_destroy(&...freechain.mutex)) {...} */

	if (ret = mutex_destroy(&ht->stats.slabs.mutex)) {
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (mutex_destroy(&...slabs.mutex)) {...} */


	/*
	 * Put back the table lock.
	 */
	if (ret = rw_unlock(&ht->tablelock)) {

		/*
		 * Bad deal! But no known possibility for recovery.
		 */
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);
		return (-2);

	} /* if (rw_unlock(&ht->tablelock)) {...} */

	/*
	 * Destroy the lock so noone else can use it.
	 */
	if (ret = rwlock_destroy(&ht->tablelock)) {

		/*
		 * Again, we're screwed. There should be a valid lock here!
		 */
		errno = (errno ? errno : ret);
		(void) ht_counter_add(&ht->stats.errors, 1);
		return (-2);

	} /* if (rwlock_destroy(&ht->tablelock)) {...} */

	/*
	 * Error counter done last just for fun!
	 */
	if (ret = mutex_destroy(&ht->stats.errors.mutex)) {

		/*
		 * Not place to record this, but I can tell the caller.
		 */
		errno = (errno ? errno : ret);
		return (-2);

	} /* if (mutex_destroy(&...errors.mutex)) {...} */

	/*
	 * So, release the table head...
	 */
	(void) free(ht);
	return (0);

} /* void ht_destroy(hashtable_t *ht, int keysize) {...} */

/*
 *
 *  int
 *  ht_resize(hashtable_t *Eht, size_t numents);
 *
 *  Description:
 *	Resize the table to hold the number of entries specified. The size may
 *	increase or decrease.
 *
 *  Paramaters:
 *	hashtable_t *Eht
 *		Pointer to the table head of the hash table to resize.
 *
 *	size_t numents
 *		New size in hash entries of the table.
 *
 *  Return value:
 *	int	If resize succeeds, the zero will be returned. Otherwise a
 *		non-zero value will be returned.
 */
int
ht_resize(void *Eht, size_t numents)
{
	/*
	 * Locals...
	 */
	hashtable_t		*ht = (hashtable_t *)Eht;
	hashtable_t		*nht;	/* New, bigger, better.		*/
	hashtable_entry_t	*hte;	/* Pointer to an entry.		*/
	hashtable_entry_t	*chte;	/* Chained entry.		*/
	hashtable_slab_t	*slabs;	/* For swapping pointers.	*/
	int			 ret;	/* Just a return value.		*/
	int			 fret;	/* free unlock return value.	*/
	int			 tret;	/* table unlock return value.	*/
	int			 sret;	/* sweep return value.		*/

	/*
	 * Only one resize may progress at a time!
	 */
	if (errno = mutex_lock(&ht->resizemutex)) {
		/*
		 * That didn't work at all!
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);
		return (-2);

	} /* if (errno = mutex_lock(ht->resizemutex)) {...} */

	/*
	 * Insert and delete lock the table for writing just long enough to
	 * lock	individual entries, then surrender the table lock. So...
	 * I can read lock old table -- No one gets in for write access
	 */
	if (errno = rw_rdlock(&ht->tablelock)) {
		/*
		 * That didn't work at all!
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);
		(void) mutex_unlock(&ht->resizemutex);
		return (-2);

	} /* if (rw_rdlock (&ht->tablelock)) {...} */

	/*
	 * Create a whole new table without implicit resize, just to keep
	 * life simple. We don't wanna recurse while resizing the table...
	 * Whadathot? That makes my head hurt. So, I won't allow it.
	 */
	nht = ht_create(numents,
	    ht->keysize,
	    ht->options & ~hto_resize_implicit);

	if (nht == (hashtable_t *)NULL) {
		(void) ht_counter_add(&ht->stats.errors, 1);
		(void) rw_unlock(&ht->tablelock);
		(void) mutex_unlock(&ht->resizemutex);
		return (-1);

	} /* if (newslab == (hashtable_slab_t *)NULL) {...} */

	/*
	 * Put this table on the "old" chain so I can find it later.
	 */
	nht->old	= ht->old;
	ht->old		= nht;

	/*
	 * Populate new table from existing table entries while reads continue
	 * to use old table during this process.
	 */
	hte = &ht->table->header.entry[ht->table->header.entrycount];
	while (hte-- != ht->table->header.entry) {

		/*
		 * Put this entry in the new table.
		 */
		if ((hte->flags & htef_occupied) &&
		    (ht_insert_key(nht, hte->key, hte->data))) {

			/*
			 * Couldn't populate the new table for some reason!
			 */
			(void) ht_counter_add(&ht->stats.errors, 1);
			if (ht_destroy(nht) == 0) {
				ht->old = (hashtable_t *)NULL;

			} /* if (ht_destroy(nht) == 0) {...} */

			(void) rw_unlock(&ht->tablelock);
			(void) mutex_unlock(&ht->resizemutex);
			return (-1);

		} /* if (ht_insert_key_(ht, hte->key, hte->data)) {...} */

		/*
		 * Walk the chain and put each entry in the new table.
		 */
		chte = hte;
		while ((chte  = chte->next) != (hashtable_entry_t *)NULL) {

			/*
			 * Put this entry in the new table.
			 */
			if (ht_insert_key(nht, chte->key, chte->data)) {

				/*
				 * Couldn't populate the new table for some
				 * reason!
				 */
				(void) ht_counter_add(&ht->stats.errors, 1);
				if (ht_destroy(nht) == 0) {
					ht->old = (hashtable_t *)NULL;

				} /* if (ht_destroy(nht) == 0) {...} */
				(void) rw_unlock(&ht->tablelock);
				(void) mutex_unlock(&ht->resizemutex);
				return (-1);

			} /* if (ht_insert_key(nht, ...)) {...} */

		} /* while ((chte  = hte->next) != (... *)NULL) {...} */

	} /* for (; hte != ht->table->header.entry; --hte) {...} */

	/*
	 * Gotta have the free lock to manupilate the slab or free chains.
	 */
	if (ret = rw_wrlock(&ht->freelock)) {

		/*
		 * Ouch!
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);
		if (ht_destroy(nht) == 0) {
			ht->old = (hashtable_t *)NULL;

		} /* if (ht_destroy(nht) == 0) {...} */

		errno = ret;
		(void) rw_unlock(&ht->tablelock);
		(void) mutex_unlock(&ht->resizemutex);
		return (-2);

	} /* if (rw_wrlock(&ht->freelock)) {...} */

	/*
	 * Swap slab lists.
	 */
	slabs		= ht->slabs;
	ht->slabs	= nht->slabs;
	nht->slabs	= slabs;

	/*
	 * Swap the free chains.
	 */
	hte		= ht->freechain;
	ht->freechain	= nht->freechain;
	nht->freechain	= hte;

	/*
	 * Swap the table pointers themselves so everyone starts using the
	 * new table.
	 */
	slabs		= ht->table;
	ht->table	= nht->table;
	nht->table	= slabs;

	/*
	 * Accumulate stats from the two tables. All of the counters simply
	 * get added together.
	 */
	(void) ht_counter_add(&ht->stats.probes,  nht->stats.probes.value);
	(void) ht_counter_add(&ht->stats.hits,    nht->stats.hits.value);
	(void) ht_counter_add(&ht->stats.errors,  nht->stats.errors.value);
	(void) ht_counter_add(&ht->stats.resizes, nht->stats.resizes.value);
	(void) ht_counter_add(&ht->stats.inserts, nht->stats.inserts.value);
	(void) ht_counter_add(&ht->stats.deletes, nht->stats.deletes.value);

	/*
	 * Averages, need to be accumulated... Counts get summed, maximums
	 * get MAX'd, and current gets saved.
	 */
	(void) ht_average_update(&ht->stats.searches,
	    nht->stats.searches.count,
	    nht->stats.searches.sum,
	    nht->stats.searches.current,
	    nht->stats.searches.maximum);

	(void) ht_average_update(&ht->stats.depth,
	    nht->stats.depth.count,
	    nht->stats.depth.sum,
	    nht->stats.depth.current,
	    nht->stats.depth.maximum);

	(void) ht_average_update(&ht->stats.freechain,
	    nht->stats.freechain.count,
	    nht->stats.freechain.sum,
	    nht->stats.freechain.current,
	    nht->stats.freechain.maximum);

	/*
	 * Done messin' with the free and slab chains.
	 */
	if (fret = rw_unlock(&ht->freelock)) {

		/*
		 * I don't dare stop now!
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (rw_unlock(&ht->freelock)) {...} */

	/*
	 * Copacetic. Everyone will now use the new table. In fact, readers
	 * are already using it. Give up the lock and let writers in for a bit.
	 */
	if (tret = rw_unlock(&ht->tablelock)) {

		/*
		 * Ouch! If I couldn't give up the lock then I probably won't
		 * be able to take it again later...
		 * But I can't bail here. Just count the error and stumble on.
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (rw_unlock(&ht->tablelock)) {...} */

	/*
	 * Sweep the old table.
	 */
	if (sret = ht_sweep(nht)) {

		/*
		 * Couldn't even sweep the old table!
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (ht_sweep(nht)) {...} */

	/*
	 * Cleaned and swept. Destroy the old table.
	 */
	if (tret == 0 &&
	    sret == 0 &&
	    ht_destroy(nht) == 0) {

		/*
		 * Swept and destroyed!
		 */
		ht->old = (hashtable_t *)NULL;

	} else {
		/*
		 * Couldn't destroy it? Count the error and stumble on.
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (tret == 0 && ... && ht_destroy(nht) == 0) {...} else {...} */

	/*
	 * Give back the resize mutex, and it's time to leave.
	 */
	if (ret = mutex_unlock(&ht->resizemutex)) {
		/*
		 * Couldn't give back the mutex lock?
		 * Just count the error and stumble on...
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (ret = mutex_unlock(&ht->resizemutex)) {...} */

	/*
	 * Set errno based on the return values of the various unlock
	 * functions.
	 */
	errno =
	    (fret != 0 ? fret :	(tret != 0 ? tret : (sret != 0 ? sret : ret)));

	/*
	 * All done... new table is already in use, and old table has been
	 * swept and destroyed.
	 */
	ret = (fret != 0 || tret != 0 || ret != 0 ? -2 : (sret != 0 ? -1 : 0));
	return (ret);

} /* int ht_resize(void *Eht, size_t numents) {...} */

/*
 *
 *  static hashtable_entry_t *
 *  ht_locate_entry_(hashtable_t *ht,
 *		      void *key,
 *		      hashtable_entry_t **previous,
 *		      hashtable_entry_t **base);
 *
 *  Description:
 *	Locate the entry in the table that matches the key passed. This is
 *	considered an internal routine and does not obtain the lock on the
 *	table. Since it may be called from either locate or delete functions
 *	the lock method require may be either read or write depending on the
 *	caller. So, the caller must supply the lock function by reference.
 *
 *  Paramaters:
 *	hashtable_t *ht
 *		Input - Pointer to the head of the hash table in which to
 *		search for the key passed.
 *
 *	void *key
 *		Input - Pointer to the bytes of the key to locate.
 *
 *	int (*lockfunc)(rwlock_t *rwlock)
 *		Input - Pointer to the rwlock function to use when locking
 *		entries.
 *
 *	hashtable_entry_t **previous
 *		Input/Output - Optional (NULL) - Pointer to a place to store
 *		the address of the previous entry if the one located happens
 *		to be on a chain. This entry will be locked using the lock
 *		function passed. If no matching key is found, then this
 *		parameter will remain unchanged.
 *
 *  Return value:
 *	hashtable_entry_t * A pointer to an entry in the table with a key that
 *		matches the one passed. The entry will be locked using the
 *		lock function passed. If no match can be found then NULL will
 *		be returned and errno will be set as follows:
 *
 *		ENOENT	2	No such file or directory
 *				If there is no entry whose key matches the key
 *				passed.
 */
static hashtable_entry_t *
ht_locate_entry_(hashtable_t *ht,
    void *key,
    int (*lockfunc)(rwlock_t *rwlock),
    hashtable_entry_t **previous)
{
	/*
	 * Locals...
	 */
	size_t			 hash_index;	/* Index for new entry.	*/
	hashtable_entry_t	*dhte;	/* Destination hash table entry. */
	hashtable_entry_t	*phte;	/* 'previous' hash table entry.	*/
	hashtable_entry_t	*pphte;	/* previous 'previous' entry.	*/
	int			 depth;	/* Search depth.		*/
	int			 ret;	/* Just a return value.		*/

	/*
	 * Keep some stats to pay the rent.
	 */
	(void) ht_counter_add(&ht->stats.probes, 1);

	/*
	 * Compute the hash value, then start checking the table.
	 */
	hash_index = (*(ht->hash_compute))(key,
	    ht->keysize,
	    ht->table->header.entrycount);

	/*
	 * Figure out the hash table index and read lock the entry.
	 */
	dhte = &ht->table->header.entry [hash_index];
	if ((*lockfunc)(&dhte->rwlock)) {
		(void) ht_counter_add(&ht->stats.errors, 1);
		return ((hashtable_entry_t *)NULL);

	} /* if ((*lockfunc)(&dhte->rwlock)) {...} */

	if (! (dhte->flags & htef_occupied)) {
		errno = ENOENT;
		(void) rw_unlock(&dhte->rwlock);
		return ((hashtable_entry_t *)NULL);

	} /* if (! (dhte->flags & htef_occupied)) {...} */

	/*
	 * Find the entry on this chain whose key matches the one passed.
	 */
	pphte =
	    phte = (hashtable_entry_t *)NULL;

	depth = 0;
	while (((*(ht->key_compare))(dhte->key, key, ht->keysize)) != 0) {
		/*
		 * Check for another one on the chain.
		 */
		++depth;
		pphte	= phte;
		phte	= dhte;
		if ((dhte = dhte->next) == (hashtable_entry_t *)NULL) {

			/*
			 * No entry found. Give up the locks and leave...
			 */
			errno = ENOENT;
			if (pphte != (hashtable_entry_t *)NULL) {
				(void) rw_unlock(&pphte->rwlock);

			} /* if (phte != (hashtable_entry_t *)NULL) {...} */

			(void) rw_unlock(&phte->rwlock);
			(void) ht_average_increment(&ht->stats.searches,
			    depth);

			return ((hashtable_entry_t *)NULL);

		} /* if ((dhte = dhte->next) == ...) {...} */

		/*
		 * Lock this entry.
		 */
		if ((*lockfunc)(&dhte->rwlock)) {

			/*
			 * Couldn't lock the current entry.
			 */

			if (pphte != (hashtable_entry_t *)NULL) {
				(void) rw_unlock(&pphte->rwlock);

			} /* if (phte != (hashtable_entry_t *)NULL) {...} */

			(void) rw_unlock(&phte->rwlock);
			(void) ht_average_increment(&ht->stats.searches,
			    depth);

			(void) ht_counter_add(&ht->stats.errors, 1);
			return ((hashtable_entry_t *)NULL);

		} /* if ((*lockfunc)(&dhte->rwlock)) {...} */

		/*
		 * Unlock the previous previous entry.
		 */
		if (pphte != (hashtable_entry_t *)NULL) {

			if (ret = rw_unlock(&pphte->rwlock)) {
				/*
				 * Something didn't work very well. Unlock the
				 * previous entry and bail.
				 */
				(void) rw_unlock(&phte->rwlock);
				(void) rw_unlock(&dhte->rwlock);
				(void) ht_average_increment(
					&ht->stats.searches,
					    depth);

				(void) ht_counter_add(&ht->stats.errors, 1);
				errno = ret;
				return ((hashtable_entry_t *)NULL);

			} /* if (rw_unlock (&pphte->rwlock)) {...} */

		} /* if (pphte != (hashtable_entry_t *)NULL) {...} */

	} /* while ( ! (*(ht->key_compare))(...)) {...} */

	/*
	 * Update the stats.
	 */
	(void) ht_average_increment(&ht->stats.searches, depth);
	(void) ht_counter_add(&ht->stats.hits, 1);

	/*
	 * If the caller was interested in the previous entry as well, then
	 * set the address.
	 */
	if (previous != (hashtable_entry_t **)NULL) {
		*previous = phte;

	} else /* if (previous == (hashtable_entry_t **)NULL) {..} */ {

		/*
		 * Not interested in the previous address. If there is a
		 * previous address, give up the lock on it.
		 */
		if (phte != (hashtable_entry_t *)NULL) {

			if (ret = rw_unlock(&phte->rwlock)) {
				/*
				 * Couldn't give up the lock?
				 * Count the error and clear out as best as I
				 * can.
				 */
				(void) rw_unlock(&dhte->rwlock);
				(void) ht_counter_add(&ht->stats.errors, 1);
				errno = ret;
				return ((hashtable_entry_t *)NULL);

			} /* if (rw_unlock (&phte->rwlock)) {...} */

		} /* if (phte != (hashtable_entry_t *)NULL) {...} */

	} /* if (previous != (hashtable_entry_t **)NULL) {...} else {...} */

	/*
	 * Return the found entry.
	 */
	return (dhte);

} /* hashtable_entry_t *ht_locate_entry(hashtable_t *ht, void *key) {...} */

/*
 *
 *  static hashtable_entry_t *
 *  ht_locate_entry(hashtable_t *ht, void *key);
 *
 *  Description:
 *	Locate the entry in the table that matches the key passed.
 *
 *  Paramaters:
 *	hashtable_t *ht
 *		Input - Pointer to the head of the hash table in which to
 *		search for the key passed.
 *
 *	void *key
 *		Input - Pointer to the bytes of the key to locate.
 *
 *  Return value:
 *	See ht_locate_entry_() with the addition that read lock for this
 *		entry has been taken on behalf of the current thread.
 *
 */
static hashtable_entry_t *
ht_locate_entry(hashtable_t *ht, void *key)
{
	/*
	 * Locals...
	 */
	hashtable_entry_t	*hte;	/* Pointer to the entry returned. */
	int			 ret;	/* Just a return value.	*/

	/*
	 * Take the table lock for reading.
	 */
	if (errno = rw_rdlock(&ht->tablelock)) {
		(void) ht_counter_add(&ht->stats.errors, 1);
		return ((void *)NULL);

	} /* if (rw_rdlock (&ht->tablelock)) {...} */

	hte = ht_locate_entry_(ht,
	    key,
	    rw_rdlock,
	    (hashtable_entry_t **)NULL);

	/*
	 * Give the table lock back.
	 */
	if (ret = rw_unlock(&ht->tablelock)) {

		/*
		 * Couldn't give back the table lock? Be sure to give up the
		 * entry lock if I have one.
		 */
		if (hte != (hashtable_entry_t *)NULL) {
			(void) rw_unlock(&hte->rwlock);

		} /* if (hte != (hashtable_entry_t *)NULL) {...} */

		(void) ht_counter_add(&ht->stats.errors, 1);
		errno = ret;
		return ((void *)NULL);

	} /* if (rw_unlock(&ht->tablelock)) {...} */

	/*
	 * Return the pointer to the entry. It's still read locked.
	 */
	return (hte);

} /* hashtable_entry_t ht_locate_entry_(hashtable_t *ht, ...) {...} */

/*
 *
 *  void *
 *  ht_locate_key(hashtable_t *Eht, void *key);
 *
 *  Description:
 *	Locate the entry in the hash table that matches the key passed and
 *	return the address of the associated data. No locks are held upon
 *	return from this function.
 *
 *  Paramaters:
 *	hashtable_t *Eht
 *		Input - Pointer to the head of the hash table in which to
 *		search for the key passed.
 *
 *	void *key
 *		Input - Pointer to the bytes of the key to locate.
 *
 *  Return value:
 *	void *	A pointer to data associated with a key that matches the one
 *		passed. If no match can be found then NULL will
 *		be returned and errno will be set as follows:
 *
 *		ENOENT	2	No such file or directory
 *				If there is not entry whose key matches the key
 *				passed.
 */
void *
ht_locate_key(void *Eht, void *key)
{
	/*
	 * Locals...
	 */
	hashtable_t		*ht = (hashtable_t *)Eht;
	hashtable_entry_t	*hte;
	void			*data;
	int			 ret;

	/*
	 * Ask big brother for the answer.
	 */
	hte = ht_locate_entry(ht, key);
	if (hte == (hashtable_entry_t *)NULL) {
		return ((void *)NULL);

	} /* if (hte == (hashtable_entry_t *)NULL) {...} */

	/*
	 * Save a pointer to the data.
	 */
	data = hte->data;

	/*
	 * Give up the lock on the entry.
	 */
	if (ret = rw_unlock(&hte->rwlock)) {
		(void) ht_counter_add(&ht->stats.errors, 1);
		errno = ret;
		return ((void *)NULL);

	} /* if (rw_unlock (&hte->rwlock)) {...} */

	/*
	 * Return the pointer to the data.
	 */
	return (data);

} /* void *ht_locate_key(hashtable_t *ht, void *key) {...} */

/*
 *
 *  int
 *  ht_insert_key(hashtable_t *Eht, void *key, void *data);
 *
 *  Description:
 *	Insert the data with the specified key into the hash table.
 *
 *  Paramaters:
 *	hashtable_t *Eht
 *		Input - Pointer to the head of the table into which to insert
 *		the entry passed.
 *
 *	void *key
 *		Input - Pointer to the bytes of the key value used for
 *		insertion.
 *
 *	void *data
 *		Input - Pointer to the buffer containing the data associated
 *		with the key.
 *
 *  Return value:
 *	int	If insertion succeeds, a copy of the entry will be placed in
 *		the table and zero (0) will be returned. If insertion fails,
 *		it may be for any of several reason -- including disallowed
 *		duplicate entries. In failure cases a non-zero value will be
 *		returned and errno will be set indiciting the reason for
 *		failure. Errno may be set by underlying routines such as
 *		malloc() used to resize the table, or it may be set
 *		explicitly due to options in the hash table. Possible explicit
 *		values include the following:
 *
 *		EEXIST	17	File exists
 *			If duplicate keys have been disallowed and the key of
 *			the entry passed matches the key of an entry already in
 *			the table.
 *
 *
 */
int
ht_insert_key(void *Eht, void *key, void *data)
{
	/*
	 * Locals...
	 */
	hashtable_t		*ht = (hashtable_t *)Eht;
	size_t			 hash_index;	/* Index for new entry.	*/
	hashtable_entry_t	*dhte;	/* Destination hash table entry. */
	hashtable_entry_t	*ohte;	/* Outside table entry.		*/
	hashtable_slab_t	*slab;	/* For new free chain allocation. */
	u_longlong_t		 depth;	/* Chain depth.			*/
	int			 ret;	/* Just a return value.		*/

	/*
	 * Keep some stats to pay the rent.
	 */
	(void) ht_counter_add(&ht->stats.inserts, 1);

	/*
	 * Take the table lock for writing just so no one moves it around
	 * while we're working here.
	 */
	if (errno = rw_wrlock(&ht->tablelock)) {
		(void) ht_counter_add(&ht->stats.errors, 1);
		return (-2);

	} /* if (rw_rdlock(&ht->tablelock)) {...} */

	/*
	 * Keep some stats to pay the rent.
	 */
	(void) ht_counter_add(&ht->stats.probes, 1);

	/*
	 * Compute hash value and look for an opening...
	 */
	hash_index = (*(ht->hash_compute))(key,
	    ht->keysize,
	    ht->table->header.entrycount);

	/*
	 * Take the lock before looking at anything!
	 */
	dhte = &ht->table->header.entry [hash_index];
	if (ret = rw_wrlock(&dhte->rwlock)) {
		/*
		 * Couldn't get the entry lock?
		 * Just count the error and stumble on.
		 */
		(void) rw_unlock(&ht->tablelock);
		(void) ht_counter_add(&ht->stats.errors, 1);
		errno = ret;
		return (-2);

	} /* if (rw_wrlock(&dhte->rwlock)) {...} */

	/*
	 * I've found the entry for this key and no longer need the whole
	 * table locked. The write lock on this entry is sufficient to prevent
	 * corruption.
	 */
	if (ret = rw_unlock(&ht->tablelock)) {

		/*
		 * Screwed!
		 */
		(void) rw_unlock(&dhte->rwlock);
		(void) ht_counter_add(&ht->stats.errors, 1);
		errno = ret;
		return (-2);

	} /* if (rw_unlock(&ht->tablelock)) {...} */

	/*
	 * Is this entry empty?
	 */
	if (! (dhte->flags & htef_occupied)) {
		/*
		 * Fill the entry, drop the lock and return.
		 */
		dhte->flags    |= htef_occupied;
		dhte->key	= key;
		dhte->data	= data;

		if (ret = rw_unlock(&dhte->rwlock)) {

			/*
			 * What should I tell the caller. The entry has
			 * been inserted, but I couldn't release the
			 * lock? Tell the user there was an error.
			 */
			(void) ht_counter_add(&ht->stats.errors, 1);
			errno = ret;
			return (-2);

		} /* if (rw_unlock(&dhte->rwlock)) {...} */

		/*
		 * This one's in the table and I'm out 'o here!
		 */
		return (0);

	} /* if ( ! (dhte->flags & htef_occupied)) {...} */

	/*
	 * So, the slot I wanted is occupied. Check for duplicates. If
	 * not allowed, then bail if I find one.
	 */

	depth	= 0;
	ohte	= dhte;
	while ((ohte != (hashtable_entry_t *)NULL)) {

		/*
		 * Check to see if the key for the current entry matches.
		 */
		if ((! (ht->options & hto_dups_allowed)) &&
		    ((*(ht->key_compare))(ohte->key, key, ht->keysize)) == 0) {

			/*
			 * Found a match, update the search depth stats. We
			 * only got here because dups are not allowed -- so we
			 * had to search to make sure there wasn't one.
			 */
			(void) ht_average_increment(&ht->stats.searches,
			    depth);

			/*
			 * We got a hit!
			 *
			 * Keep some stats to pay the rent.
			 */
			(void) ht_counter_add(&ht->stats.hits, 1);

			/*
			 * Set the error indicating that a duplicate
			 * key was found, but that ain't allowed.
			 */
			errno = EEXIST;

			if (ret = rw_unlock(&dhte->rwlock)) {
				/*
				 * If putting back the lock failed,
				 * then errno has a lock relavent
				 * value to override the dups not
				 * allowed indication. Something BIGGER
				 * is broken!
				 */
				(void) ht_counter_add(&ht->stats.errors, 1);
				errno = ret;
				return (-2);

			} /* if (rw_unlock(&dhte->rwlock)) {...} */

			return (-1);

		} /* if ((! (ht->options & hto_dups_allowed)) &&...} */

		/*
		 * Keep track of the depth and move on to the next entry...
		 */
		++depth;
		ohte = ohte->next;

	} /* while ((! (ht->options & hto_dups_allowed)) && ...) {...} */

	/*
	 * If dup were not allowed, then we just searched and did not find one.
	 * So the search stats need to be updated.
	 */
	if (! (ht->options & hto_dups_allowed)) {

		(void) ht_average_increment(&ht->stats.searches, depth);

	} /* if (! (ht->options & hto_dups_allowed)) {...} */

	/*
	 * Okay, no duplicates, but the table entry is occupied. Hang the new
	 * one on the chain from this entry.
	 *
	 * Since this won't be in the table itself, allocate some space to hold
	 * it. Try to get an entry from the free chain first. If the free chain
	 * is empty, allocate another slab of free ones.
	 */

	/*
	 * Take the free chain lock.
	 */
	if (ret = rw_wrlock(&ht->freelock)) {

		/*
		 * Couldn't get the lock. Just leave the entry where it is.
		 */
		(void) rw_unlock(&dhte->rwlock);
		(void) ht_counter_add(&ht->stats.errors, 1);
		errno = (errno ? errno : ret);
		return (-2);

	} /* if (rw_wrlock(&ht->freelock)) {...} */

	/*
	 * If there's nothing to take from the free chain. Make some more.
	 */
	while ((ohte = ht->freechain) == (hashtable_entry_t *)NULL) {
		/*
		 * Allocate a slab the same size as the table itself.
		 */
		slab = ht_create_slab(ht->table->header.entrycount);
		if (slab == (hashtable_slab_t *)NULL) {

			/*
			 * Couldn't create any more free entries.
			 */
			(void) rw_unlock(&ht->freelock);
			(void) rw_unlock(&dhte->rwlock);
			(void) ht_counter_add(&ht->stats.errors, 1);
			return (-1);

		} /* if (slab == (hashtable_slab_t *)NULL) {...} */

		/*
		 * Put the slab on the list of slabs.
		 */
		(void) ht_counter_add(&ht->stats.slabs, 1);
		slab->header.next	= ht->slabs;
		ht->slabs		= slab;

		/*
		 * Dangle all the entries from the free chain.
		 */
		ohte = &slab->header.entry[slab->header.entrycount];
		while (ohte-- != slab->header.entry) {
			ohte->next	= ht->freechain;
			ht->freechain	= ohte;

		} /* while (--ohte != &slab->header.entry [...]) {...} */

		/*
		 * Update the free chain stats.
		 */
		(void) ht_average_update(&ht->stats.freechain,
		    1,	/* Added them all at once. */
		    slab->header.entrycount,
		    ht->stats.freechain.current + slab->header.entrycount,
		    ht->stats.freechain.current + slab->header.entrycount);

	} /* while ((ohte = ht->freechain) == (... *)NULL) {...} */

	/*
	 * Take ohte off the free chain.
	 */
	ht->freechain	= ohte->next;
	ohte->next	= (hashtable_entry_t *)NULL;
	(void) ht_average_increment(&ht->stats.freechain,
	    ht->stats.freechain.current - 1);

	/*
	 * Put the free chain lock back.
	 */
	if (ret = rw_unlock(&ht->freelock)) {
		/*
		 * What should I do here? Returning would orphan the entry.
		 * Just muddle forward.
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);
		errno = (errno ? errno : ret);

	} /* if (rw_unlock(&ht->freelock)) {...} */

	/*
	 * Copy the information into the entry to keep with the table
	 * and mark it as occupied.
	 */
	ohte->flags    |= htef_occupied;
	ohte->key	= key;
	ohte->data	= data;

	/*
	 * Put this entry at the beginning of the chain, and we're
	 * outa here!
	 */
	ohte->next = dhte->next;
	dhte->next = ohte;

	/*
	 * Update the chain depth stats.
	 */
	(void) ht_average_increment(&ht->stats.depth, depth);

	/*
	 * Free the locks and we're outa here!
	 */
	if (ret = rw_unlock(&dhte->rwlock)) {
		/*
		 * Dilema! The entry could be inserted, but I couldn't
		 * unlock the entry... We're screwed, the entry has
		 * been hosed.  What should I tell the caller? For now
		 * return the error to the caller.
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);
		errno = (errno ? errno : ret);
		return (-2);

	} /* if (rw_unlock(&dhte->rwlock)) {...} */

	/*
	 * Okay, we're safe. The entry is in the table. Now, did we just cross
	 * the threshold requiring the table to resize?
	 */
	if ((ht->options & hto_resize_implicit) &&
	    (ht->threshold_evaluate != NULL)) {

		/*
		 * Okay, I'm allowed to perform implicit resizes, and i have
		 * a pointer to a funtion. Call it to see if a resize should be
		 * done now.
		 */

		ret = (*(ht->threshold_evaluate))(ht->table->header.entrycount,
		    ht->stats.depth.count,
		    ht->stats.depth.sum,
		    ht->stats.searches.count,
		    ht->stats.searches.sum);

		if (ret != 0) {
			return (ht_resize(ht,
			    ht->table->header.entrycount * 2));

		} /* if (ret != 0) {...} */

	} /* if ((ht->options & hto_resize_implicit) && ...) {...} */

	/*
	 * All done...
	 */
	return (0);

} /* int ht_insert_key(hashtable_t *ht, void *key, void *data) {...} */

/*
 *
 *  void *
 *  ht_delete_key(hashtable_t *Eht, void *key);
 *
 *  Description:
 *	Mark an entry not occupied. If the entry happens to be chained to an
 *	entry in the table, the put it on the free chain.
 *
 *  Paramaters:
 *	hashtable_t *Eht
 *		Input - Pointer to the head of the hash table from the the
 *		key should be deleted.
 *
 *	void *key
 *		Input - Pointer to the bytes of the key to delete;
 *
 *  Return value:
 *	int	Upon successful removal of the entry containing the key from
 *		the table the address of the data will be returned. If the
 *		entry is not in the table, the NULL will be returned and errno
 *		set as returned from ht_locate_entry_().
 */
void *
ht_delete_key(void *Eht, void *key)
{
	/*
	 * Locals...
	 */
	hashtable_t		*ht = (hashtable_t *)Eht;
	hashtable_entry_t	*dhte;	/* Destination hash table entry. */
	hashtable_entry_t	*phte;	/* 'previous' chain entry.	*/
	int			 ret;	/* Just a return value.		*/
	int			 fret;	/* Free chain lock return.	*/
	int			 pret;	/* Previous entry lock return.	*/

	/*
	 * Keep some stats.
	 */
	(void) ht_counter_add(&ht->stats.deletes, 1);

	/*
	 * Take the table lock for writing.
	 */
	if (errno = rw_wrlock(&ht->tablelock)) {
		(void) ht_counter_add(&ht->stats.errors, 1);
		return ((void *)NULL);

	} /* if (rw_wrlock(&ht->tablelock)) {...} */

	/*
	 * Locate the entry with this key.
	 */
	dhte = ht_locate_entry_(ht, key, rw_wrlock, &phte);

	/*
	 * If I got an entry, it's locked. If I didn't find an entry there's
	 * nothing to do here. Either way, I don't need the table lock any
	 * longer.
	 */
	ret = rw_unlock(&ht->tablelock);

	/*
	 * Did I find an entry?
	 */
	if (dhte == (hashtable_entry_t *)NULL) {

		/*
		 * Nope.
		 */
		return ((void *)NULL);

	} /* if (dhte == (hashtable_entry_t *)NULL) {...} */

	/*
	 * Did I have trouble releasing the table lock?
	 */
	if (ret != 0) {

		/*
		 * Yes, so release the lock on the entry and bail!
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);
		(void) rw_unlock(&dhte->rwlock);
		errno = ret;
		return ((void *)NULL);

	} /* if (ret != 0) {...} */

	/*
	 * Is this entry on a chain or in the table proper?
	 */
	if (phte == (hashtable_entry_t *)NULL) {

		/*
		 * This is an entry in the table proper. If there is no chain
		 * then simply mark it an unoccupied.
		 */
		if (dhte->next == (hashtable_entry_t *)NULL) {

			/*
			 * Just mark this one an unoccupied.
			 */
			dhte->flags &= ~htef_occupied;
			return (dhte->data);

		} /* if (dhte->next == (hashtable_entry_t *)NULL) {...} */

		/*
		 * There is a chain. Point to the next one and fetch a write
		 * lock on it.
		 */
		phte = dhte;
		dhte = dhte->next;
		if (ret = rw_wrlock(&dhte->rwlock)) {

			/*
			 * Ouch! Couldn't lock the entry.
			 */
			(void) rw_unlock(&phte->rwlock);
			(void) ht_counter_add(&ht->stats.errors, 1);
			errno = ret;
			return ((void *)NULL);

		} /* if (rw_rdlock(&dhte->next->rwlock)) {...} */

		/*
		 * Copy the content into the entry in the table.
		 */
		phte->key	= dhte->key;
		phte->data	= dhte->data;
		phte->flags	= dhte->flags;

		/*
		 * Fall through to put it on the free chain.
		 * dhte now points to the one to remove from the chain, phte
		 * points to the previous one, and both have been write
		 * locked -- just like ht_locate_entry_() returns.
		 */

	} /* if (phte == (hashtable_entry_t *)NULL) {...} */

	/*
	 * Mark the entry as empty, but leave it on the chain for a bit...
	 */
	dhte->flags	&= ~htef_occupied;

	/*
	 * Get a write lock on the free chain so I can put this one on the
	 * chain.
	 */
	if (ret = rw_wrlock(&ht->freelock)) {

		/*
		 * Could not get the lock!
		 */
		(void) rw_unlock(&phte->rwlock);
		(void) rw_unlock(&dhte->rwlock);
		(void) ht_counter_add(&ht->stats.errors, 1);
		errno = ret;
		return ((void *)NULL);

	} /* if (rw_wrlock(&ht->freechain->rw_lock)) {...} */

	/*
	 * I've got the free chain. Put this new free one on it.
	 */
	phte->next	= dhte->next;	/* Out of the free chain.	*/
	dhte->next	= ht->freechain; /* Pick up free chain head.	*/
	ht->freechain	= dhte;		/* Point free chain here.	*/

	/*
	 * Just need to put back the locks... for the free chain...
	 */
	if (fret = rw_unlock(&ht->freelock)) {

		/*
		 * Ouch! How could this fail?
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (fret = rw_unlock(&ht->freelock)) {...} */

	/*
	 * ... for the previous entry...
	 */
	if (pret = rw_unlock(&phte->rwlock)) {

		/*
		 * Could not put back the lock?
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (pret = rw_unlock(&phte->rwlock)) {...} */

	/*
	 * ... and on the entry being deleted.
	 */
	if (errno = rw_unlock(&dhte->rwlock)) {

		/*
		 * The work's been done, but the entry seems to have problems!
		 */
		(void) ht_counter_add(&ht->stats.errors, 1);

	} /* if (rw_unlock(&dhte->rwlock)) {...} */

	/*
	 * Tell the caller about any failures.
	 */
	if (fret || pret) {

		/*
		 * Does this mean anything? The work succeeded, but other
		 * problems seem to be lurking.
		 */
		errno = (fret ? fret : pret);

	} /* if (fret || pret) {...} */

	/*
	 * All done.
	 */
	return (errno ? (void *)NULL : dhte->data);

} /* int ht_delete_key(hashtable_t *ht, void *key) {...} */
