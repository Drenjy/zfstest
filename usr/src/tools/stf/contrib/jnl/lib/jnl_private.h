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

#ifndef _JNL_PRIVATE_H
#define	_JNL_PRIVATE_H

/*
 *	Private declaration for jnl.c
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <jnl_detail.h>
#include <note.h>
#include <thread.h>

/*
 * These titles must be in the same order as the indices listed in the
 * jnl_buffer_index enumeration found in jnl_proto.h.
 */
static char *jnl_message_title[] = {
	"Operation",
	"Expected",
	"Error",
	"Action"
};

/*
 * Buffer sizes for the various types of journal messages.
 */
typedef enum buffer_sizes {
	jnlBS_TOC	= 1024,		/* Table of contents default.	*/
	jnlBS_LOG	= 4096,		/* jnl_LOG() buffer size.	*/
	jnlBS_format	= 1024,		/* Intermediate format strings.	*/
	jnlBS_OPERATION	= 1024,		/* jnl_OPERATION() buffer size.	*/
	jnlBS_EXPECTED	= 1024,		/* jnl_EXPECTED() buffer size.	*/
	jnlBS_ERROR	= 1024,		/* jnl_ERROR() buffer size.	*/
	jnlBS_ACTION	= 1024		/* jnl_ACTION() buffer size.	*/
} buffer_sizes_t;

/*
 * The number and order of these values must match that of the text in
 * jnl_message_titles[] above.
 */
static int jnl_message_buffer_size[] = {
	jnlBS_OPERATION,
	jnlBS_EXPECTED,
	jnlBS_ERROR,
	jnlBS_ACTION
};

/*
 * Structure for a journal buffer -- an aggregation of several buffers which
 * must be available as "static" for any given thread.
 */
typedef struct jnl_buffer {
	thread_t	 thread_id;		/* Owner of this buffer	*/
	char		*buffer[jnlBI_MAX_];	/* Pointers to buffers */
} jnl_buffer_t;

/*
 * Pointer to the table of contents for the jnl_buffers.
 *
 * A hash table it used for this purpose. A void pointer is all that's
 * needed for the hash table address. The data pointer fetched from a hash
 * table entry will point to a jnl_buffer_t.
 */
static void			*jnl_toc	= (void *)NULL;

/*
 * Detail level for journal calls -- defaults to jnlDL_PROGRESS.
 */
static jnl_DetailLevel_t	_jnlDL_		= jnlDL_PROGRESS;

/*
 * Detail level descriptions -- sorted by detail level value.
 */
static jnlDL_Description_t jnlDL_Level_Descriptions[]	= {
	{jnlDL_ASSERTION,	"Assertion"},
	{jnlDL_RESULT,		"Result"},
	{jnlDL_DIAGNOSTIC,	"Diagnostic"},
	{jnlDL_PROGRESS,	"Progress"},
	{jnlDL_VERBOSE,		"Verbose"},
	{jnlDL_STACK,		"Stack"},
	{jnlDL_ENCYCLOPEDIC,	"Encyclopedic"}
};

/*
 * Detail level descriptions -- sorted by description.
 */
static jnlDL_Description_t jnlDL_Description_Levels[] = {
	{jnlDL_ASSERTION,	"Assertion"},
	{jnlDL_DIAGNOSTIC,	"Diagnostic"},
	{jnlDL_ENCYCLOPEDIC,	"Encyclopedic"},
	{jnlDL_PROGRESS,	"Progress"},
	{jnlDL_RESULT,		"Result"},
	{jnlDL_STACK,		"Stack"},
	{jnlDL_VERBOSE,		"Verbose"}
};

/*
 * A constant containing the name of the environment variable used for the
 * detail level. This isn't exactly a private variable, but it is a constant,
 * and only stored here.
 */
const char jnlDL_ENV_NAME[] = "TJNL_DETAIL";

#ifdef __cplusplus
}
#endif

#endif /* _JNL_PRIVATE_H */
