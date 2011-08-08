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

#ifndef _HASHTABLE_H
#define	_HASHTABLE_H

#pragma ident	"@(#)hashtable.h	1.3	07/04/12 SMI"

/*
 *	Hash table external prototypes, data types and options.
 */

#ifdef __cplusplus
extern "C" {
#endif

/*
 *	Generally useful stuff...
 */
#define	_ht_bit_mask(x)		(1 << (x))

/*
 *	Table options.
 */
typedef enum ht_option_bits {
	hto_resize_implicit_bit /* = 0 */, /* Should resizes be implicit? */
	hto_dups_allowed_bit	/* = 1 */  /* Are duplicates allowed?	*/
} ht_option_bit_t;

typedef enum ht_options {

	/*
	 *  Table resizing becomes necessary when too many entries are dangling
	 *  from previous entries that hashed to the same bucket. Resizing
	 *  can be done explicitly by the cleint calling ht_resize(), or
	 *  implicitly. Implicit resizing only occurs when dangling has been
	 *  disallowed and implicit resizing allowed
	 */
	hto_resize_implicit	= _ht_bit_mask(hto_resize_implicit_bit),

	/*
	 *  Duplicate entries have identicle keys, but may have different data.
	 *  Consequently, it may be perfectly legal to have such entries.
	 */
	hto_dups_allowed	= _ht_bit_mask(hto_dups_allowed_bit)

} ht_option_t;

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
    u_longlong_t searchsum);

/*
 *  unsigned int
 *  ht_hash_compute(void *key, size_t keysize)
 *
 *  Description:
 *	Compute a hash value based on the bytes passed as the key.
 *
 *  Paramaters:
 *
 *  Return value:
 */
size_t
ht_hash_bytes(void *key, size_t keysize, size_t table_size);

/*
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
 */
void *
ht_create(size_t numents, size_t keysize, ht_option_t options);

/*
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
ht_destroy(void *Eht);

/*
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
ht_resize(void *Eht, size_t numents);

/*
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
ht_locate_key(void *Eht, void *key);

/*
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
 */
int
ht_insert_key(void *Eht, void *key, void *data);

/*
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
ht_delete_key(void *Eht, void *key);

#ifdef __cplusplus
}
#endif

#endif /* _HASHTABLE_H */
