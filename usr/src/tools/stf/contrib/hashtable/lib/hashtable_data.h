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

#ifndef _HASHTABLE_DATA_H
#define	_HASHTABLE_DATA_H

#pragma ident	"@(#)hashtable_data.h	1.3	07/04/12 SMI"

/*
 *	Hash table data definitions.
 *
 *	The following data and associate code presume that all keys and data
 *	remain in storage outside of the table proper.
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <hashtable.h>
#include <synch.h>

/*
 *	Hash table entry flags.
 */
typedef enum hte_flag_bits {
	htef_occupied_bit /*	= 0 */,	/* Entry has a key.		*/
	htef_lock_init_bit /*	= 1 */	/* Lock has been initialized.	*/

} hte_flag_bit_t;

typedef enum hashtable_entry_flags {
	/*
	 * Hash table entries may be empty.
	 */
	htef_occupied		= _ht_bit_mask(htef_occupied_bit),

	/*
	 * Read/write locks in entries may or may not be usable.
	 */
	htef_lock_initialized	= _ht_bit_mask(htef_lock_init_bit)

} hashtable_entry_flag_t;

/*
 *	Structure for a single entry in the hash table.
 */
typedef struct hashtable_entry {
	rwlock_t		 rwlock; /* Lock for this entry.	*/
	struct hashtable_entry	*next;	/* Next entry if chained.	*/
	void			*key;	/* Pointer to the key.		*/
	void			*data;	/* Pointer to the data.		*/
	hashtable_entry_flag_t	flags;	/* Individual entry flags.	*/

} hashtable_entry_t;

/*
 *	Table entries are allocated in slabs. Each slab has a pointer to the
 *	next slab (actually the one previously allocated), and a pointer to
 *	the entries in this slab. So, the slab strucure is actually the header
 *	information for the slab. When the buffer gets allocated, the slab
 *	header is created at the beginning of the buffer, then entries are
 *	created following to fill the rest of the buffer.
 *
 *	+========================+
 *	| *next			 |   \
 *	+------------------------+    \
 *	| *entry		 |      slab (structure) header.
 *	+------------------------+    /
 *	| entrycount		 |   /
 *	+========================+
 *	| entry [0]		 |
 *	|  ...			 |
 *	+------------------------+
 *	| entry [1]		 |
 *	|  ...			 |
 *	+------------------------+
 *	|  ...			 |
 *	+------------------------+
 *	| entry [entrycount - 1] |
 *	|  ...			 |
 *	+========================+
 */
typedef union hashtable_slab {
	struct {
		union hashtable_slab	*next;	/* @next slab.		*/
		hashtable_entry_t	*entry;	/* @entries in slab.	*/
		size_t			 entrycount;	/* # entries.	*/

	}			header;		/* Union header.	*/
	hashtable_entry_t	entries;	/* Room for entries.	*/

} hashtable_slab_t;

/*
 * A couple of structures to make statistics collection work.
 */
typedef struct hashtable_counter {
	mutex_t		mutex;		/* Lock for this counter.	*/
	u_longlong_t	value;		/* Value of this counter.	*/

} hashtable_counter_t;

typedef struct hashtable_average {
	mutex_t		mutex;		/* Lock for this structure.	*/
	u_longlong_t	count;		/* # iterations.		*/
	u_longlong_t	sum;		/* Sum of all counts.		*/
	u_longlong_t	current;	/* Current #.			*/
	u_longlong_t	maximum;	/* Maximum chain depth.		*/

} hashtable_average_t;

/*
 *	Structure for the entire table of hash entries.
 */
typedef struct hashtable {
	rwlock_t		 tablelock;	/* Lock for the whole table. */
	rwlock_t		 freelock;	/* Lock for the free chain.  */
	mutex_t			 resizemutex;	/* Lock for resizing.	*/
	int			 keysize;	/* Byte size of an entry. */
	ht_option_t		 options;	/* Table options.	*/
	struct hashtable	*old;		/* Pointer to old tables. */
	hashtable_slab_t	*slabs;		/* Slabs of entries.	*/
	hashtable_slab_t	*table;		/* The table itself.	*/
	hashtable_entry_t	*freechain;	/* Free chain entries.	*/

	/*
	 * Pointer to the default hash computation function.
	 */
	size_t			(* hash_compute)(void *key,
	    size_t keysize,
	    size_t table_size);

	/*
	 * Pointer to the key comparison function. Caller supplied.
	 */
	int			(* key_compare)(const void *key1,
	    const void *key2,
	    size_t keysize);

	/*
	 * Pointer to the function for evaluating resize thresholds.
	 */
	int			(* threshold_evaluate)(size_t numents,
	    u_longlong_t depthcount,
	    u_longlong_t depthsum,
	    u_longlong_t searchcount,
	    u_longlong_t searchsum);

	struct {			/* Hash table statistics.	*/
		hashtable_average_t	depth;		/* chain depth info. */
		hashtable_average_t	freechain;	/* Free chain info.  */
		hashtable_average_t	searches;	/* Chain searches.   */
		hashtable_counter_t	deletes;	/* Attempted deletes */
		hashtable_counter_t	errors;		/* # errors returned */
		hashtable_counter_t	hits;		/* Successful	*/
		hashtable_counter_t	inserts;	/* Attempted inserts */
		hashtable_counter_t	probes;		/* Locates.	*/
		hashtable_counter_t	resizes;	/* #  table resizes  */
		hashtable_counter_t	slabs;		/* Slab chain info.  */

	} stats;

} hashtable_t;

#ifdef __cplusplus
}
#endif

#endif /* _HASHTABLE_DATA_H */
