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
 *
 */

#pragma ident	"@(#)libjnl.c	1.5	07/04/12 SMI"

#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <note.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <strings.h>
#include <thread.h>
#include <unistd.h>

#include <hashtable.h>
#include <stf.h>
#include <jnl.h>

/* LINTLIBRARY */

#include "jnl_private.h"

/*
 * void
 * jnl_internal_error(char *format_string, ...);
 *
 * Description:
 *	Printf an error message to the journal.
 *
 * Parameters:
 *	char *format_string
 *		Input - A printf() style format string.
 *	...
 *		Input - Sufficient parameters to satisfy the format string.
 *
 * Return value:
 *	void
 */
#if (_STF_JNL_VARIADIC_MACROS >= 1)

#define	jnl_internal_error(...) jnl_internal_error_(__FILE__, \
	__LINE__, \
	__VA_ARGS__)

NOTE(PRINTFLIKE(3))
static void
jnl_internal_error_(char *file__, int line__, char *format_string, ...)

#else

#define	jnl_internal_error	jnl_internal_error_

NOTE(PRINTFLIKE(3))
static void
jnl_internal_error_(char *format_string, ...)

#endif
{
	/*
	 * Locals...
	 */
	va_list	parms;			/* Variable argument list.	*/
	int	ret;			/* return value...		*/
	char	fmt[jnlBS_ERROR];	/* For local formatting.	*/
	char	message[jnlBS_ERROR];	/* Local message buffer.	*/

	/*
	 * Combine the file name, line number and format string into my local
	 * buffer.
	 */
#if (_STF_JNL_VARIADIC_MACROS >= 1)
	ret = snprintf(fmt,
	    sizeof (fmt),
	    "**** Error: (File %s, Line %d)\n%s",
	    file__,
	    line__,
	    format_string);
#else
	ret = snprintf(fmt,
	    sizeof (fmt),
	    "**** Error: %s",
	    format_string);
#endif
	if (ret < 0) {

		/*
		 * Couldn't even format the error message!
		 */

		(void) stf_jnl_msg("**** Error: jnl_internal_error():\n"
		    "snprintf() failed!\n"
		    "Could not format internal error message format string.");
		return;
	} /* if (ret < 0) {...} */

	/*
	 * Initialize the vargs pointer and format the caller's data into the
	 * message.
	 */

	va_start(parms, format_string);
	ret = vsnprintf(message, sizeof (message), fmt, parms);
	va_end(parms);
	if (ret < 0) {

		/*
		 * Couldn't even format the error message!
		 */
		(void) stf_jnl_msg("**** Error: jnl_internal_error():\n"
		    "vsnprintf() failed!\n"
		    "Could not format internal error message.");

	} else /* if (ret >= 0) */ {

		/*
		 * Send caller's message to the journal.
		 */
		(void) stf_jnl_msg(message);

	} /* else if (ret >= 0) {...} */

	return;

} /* void jnl_internal_error(char *format_string, ...) {...} */

/*
 *  void
 *  _jnlDL_init_()
 *
 *  Description:
 *	Initialize the detail level and create a table of contents for the
 *	message buffers. This routines gets called at library load time before
 *	main() gets invoked.
 *
 *  Parameters:
 *	None.
 *
 *  Return value:
 *	None.
 *
 *  Output:
 *	None.
 */
static void
_jnl_init_();

#pragma init(_jnl_init_)

static void
_jnl_init_() {
	/*
	 * Locals...
	 */
	char	*detail_level_env;	/* Pointer to the environment value. */
	jnlDL_Description_t	*jnlDL;	/* Pointer to a description.	*/

	/*
	 * If there is an environment variable for the detail level,
	 * then get the number and set my local copy.
	 */
	detail_level_env = getenv(jnlDL_ENV_NAME);
	if (detail_level_env != (char *)NULL) {

		/*
		 * Is it a keyword, or numeric?
		 */
		if (isdigit(detail_level_env[0])) {
			errno = 0;
			_jnlDL_ = atoi(detail_level_env);
			/*
			 * Did that work?
			 */
			if (errno != 0) {
				jnl_internal_error("_jnl_DL_init_():\n"
				    " - atoi(%s) failed with error %d",
				    detail_level_env,
				    errno);

				exit(EXIT_FAILURE);

			} /* if (errno != 0) {...} */

		} else {
			jnlDL = jnl_dl_level_fetch(detail_level_env);
			if (strcasecmp(jnlDL->description, detail_level_env)
			    == 0) {
				_jnlDL_	= jnlDL->level;

			} /* if (strcasecmp(...) {...} */

		} /* if (isdigit(detail_level_env[1])) {...} else {...} */

	} /* if (detail_level_env != (char *)NULL) {...} */

	/*
	 * Create a hashtable to keep track of message buffers.
	 */
	jnl_toc = ht_create(jnlBS_TOC, sizeof (thread_t), 0);
	if (jnl_toc == (void *)NULL) {
		jnl_internal_error("_jnl_DL_init_():\n"
		    " - ht_create(%d, %d, %d) failed with error %d",
		    jnlBS_TOC,
		    sizeof (thread_t),
		    0);

		exit(EXIT_FAILURE);

	} /* if (jnl_toc == (void *)NULL) {...} */

	return;

} /* void _jnl_init_() {...} */

/*
 * char *
 * _jnl_buffer_fetch(thread_t thread_id, jnl_buffer_index_t index);
 *
 * Description:
 *	Fetch the address of the message buffer indicated by the index passed.
 *	If there are no message buffers for this thread yet, then some will be
 *	allocated and installed into the table of content first.
 *
 * Parameters:
 *	thread_t	threadid
 *		Input - Identity of the thread whose buffers should be used.
 *
 *	jnl_buffer_index_t index
 *		Input - Index of the message buffer desired.
 *
 * Return value:
 *	char *	Pointer to the message buffer.
 */
static char *
_jnl_buffer_fetch(thread_t thread_id, jnl_buffer_index_t index)
{
	/*
	 * Locals...
	 */
	jnl_buffer_t		*jnl;	/* Buffers for this thread.	*/
	int			 ret;	/* Just a return value.		*/
	jnl_buffer_index_t	 i;	/* Buffer index.		*/
	jnl_buffer_index_t	 j;	/* Ditto...			*/

	/*
	 * Make sure we're not using bogus parameters.
	 */
	if (index < jnlBI_MIN_ || index >= jnlBI_MAX_) {
		jnl_internal_error("_jnl_buffer_fetch(%d, %d)\n"
		    "Invalid buffer index passed.",
		    thread_id,
		    index);

		return ((char *)NULL);

	} /* if (indexn < jnlBI_MIN_ || index >= jnlBI_MAX_) {...} */

	/*
	 * Probe the table of contents for buffers for the thread passed.
	 */
	jnl = (jnl_buffer_t *)ht_locate_key(jnl_toc, &thread_id);
	if (jnl == (jnl_buffer_t *)NULL) {

		/*
		 * Okay, so why didn't that work? Because this is a first time
		 * and the buffers need to be allocated, or was there a genuine
		 * error?
		 */
		if (errno != ENOENT) {

			/*
			 * Loser! Something's really broken.
			 */
			jnl_internal_error("_jnl_buffer_fetch(%d, %d)\n"
			    "ht_locate_key(%p, %p) failed.\n"
			    "errno = %d, %s",
			    thread_id,
			    index,
			    jnl_toc,
			    &thread_id,
			    errno,
			    strerror(errno));

			return ((char *)NULL);

		} /* if (errno != ENOENT && errno != ENOTDIR) {...} */

		/*
		 * Allocate a message buffer structure and the message buffers,
		 * then insert them into the table of contents.
		 */
		jnl = (jnl_buffer_t *)malloc(sizeof (*jnl));
		if (jnl == (jnl_buffer_t *)NULL) {

			/*
			 * Something's broken!
			 */
			jnl_internal_error("_jnl_buffer_fetch(%d, %d)\n"
			    "Failed to allocate message buffer toc.",
			    thread_id,
			    index);

			return ((char *)NULL);

		} /* if (buffer == (jnl_buffer_t *)NULL) {...} */

		/*
		 * Get a buffer for each message type.
		 */
		jnl->buffer[jnlBI_OPERATION]	=
		    (char *)malloc(jnlBS_OPERATION);

		jnl->buffer[jnlBI_EXPECTED]	=
		    (char *)malloc(jnlBS_EXPECTED);

		jnl->buffer[jnlBI_ERROR]	=
		    (char *)malloc(jnlBS_ERROR);

		jnl->buffer[jnlBI_ACTION]	=
		    (char *)malloc(jnlBS_ACTION);

		/*
		 * Check for allocation failures.
		 */
		for (i = jnlBI_MIN_; i < jnlBI_MAX_; ++i) {

			if (jnl->buffer[i] == (char *)NULL) {

				/*
				 * At least one of them could not be allocated.
				 * So free up everything and return failure.
				 */
				for (j = jnlBI_MIN_; j < jnlBI_MAX_; ++j) {

					(void) free(jnl->buffer[j]);

				} /* for (...; j < jnlBI_MAX_; ++j) {...} */

				(void) free(jnl);
				jnl_internal_error("jnl_buffer_fetch(%d, %d)\n"
				    "Failed to allocate message buffer(%d).",
				    thread_id,
				    index,
				    i);

				return ((char *)NULL);

			} /* if (jnl->buffer[i] == (char *)NULL) {...} */

		} /* for (... i = jnlBI_MIN_; i < jnlBI_MAX_; ++i) {...} */

		/*
		 * Put this new entry into the table of contents.
		 */
		jnl->thread_id = thread_id;
		ret = ht_insert_key(jnl_toc,
		    (void *)&jnl->thread_id,
		    (void *)jnl);

		if (ret != 0) {

			/*
			 * Huh? That didn't seem to work.
			 */
			for (j = jnlBI_MIN_; j < jnlBI_MAX_; ++j) {

				(void) free(jnl->buffer[j]);

			} /* for (...; j < jnlBI_MAX_; ++j) {...} */

			(void) free(jnl);
			jnl_internal_error("_jnl_buffer_fetch(%d, %d)\n"
			    "ht_insert_key(%p, %p, %p) returned %d.\n"
			    "Could not insert new journal buffer group.",
			    thread_id,
			    index,
			    jnl_toc,
			    &jnl->thread_id,
			    jnl,
			    ret);

			return ((char *)NULL);

		} /* if (ret != 0) {...} */

	} /* if (buffer == (jnl_buffer_t *)NULL) {...} */

	/*
	 * Return the buffer desired...
	 */
	return (jnl->buffer[index]);

} /* char *_jnl_buffer_fetch(threadid, bufferid) {...} */

/*
 *  jnl_DetailLevel_t
 *  jnl_dl_fetch(void);
 *
 *  Description:
 *      jnl_dl_fetch() returns the value of the detail level as of the first
 *	call to any of the jnl_* functions.
 *
 *  Parameters:
 *      None.
 *
 *  Return value:
 *     jnl_DetailLevel_t  The value of the detail level.
 *
 *  Output:
 *      None.
 */
#define	JNL_DL_FETCH() (_jnlDL_)

jnl_DetailLevel_t
jnl_dl_fetch(void)
{
	/*
	 * Okay, by now we have a detail level, return it.
	 */
	return (JNL_DL_FETCH());

} /* int jnl_dl_check (jnl_DetailLevel_t level) {...}  */

/*
 *  int
 *  jnl_dl_check (jnl_DetailLevel_t level);
 *
 *  Description:
 *      jnl_dl_check() returns the result of the logical comparison of
 *      the level passed with the environment variable TJNL_DETAIL using the
 *      expression (level <= TJNL_DETAIL)
 *
 *  Parameters:
 *      jnl_DetailLevel_t level
 *              Input - Detail level for query.
 *
 *  Return value:
 *      int     Returns (level <= TJNL_DETAIL)
 *
 *  Output:
 *      None.
 */
#define	JNL_DL_CHECK(l) (l <= JNL_DL_FETCH())

int
jnl_dl_check(jnl_DetailLevel_t level)
{
	/*
	 * Fetch the detail level and return the value of the comparison.
	 */
	return (JNL_DL_CHECK(level));


} /* int jnl_dl_check (jnl_DetailLevel_t level) {...} */

/*
 *  jnlDL_Description_t *
 *  jnl_dl_description_fetch (jnl_DetailLevel_t level);
 *
 *  Description:
 *      jnl_dl_description_fetch() returns a pointer to the description of the
 *	detail level passed.
 *
 *  Parameters:
 *      jnl_DetailLevel_t level
 *              Input - Detail level for query.
 *
 *  Return value:
 *      jnlDL_Description_t * Returns a pointer to a static buffer containing
 *		the complex data type for the detail level description.
 *
 *  Output:
 *      None.
 */
jnlDL_Description_t *
jnl_dl_description_fetch(jnl_DetailLevel_t level)
{
	/*
	 * Locals...
	 */
	jnlDL_Description_t	*jnlDL;		/* Pointer to descriptions. */
	jnlDL_Description_t	*jnlDL_highest;	/* Pointer to descriptions. */
	jnlDL_Description_t	*jnlDL_prev;	/* Pointer to descriptions. */
	int			 distance;	/* Traveral size.	*/

	/*
	 * How many items are then in the table..
	 */
	distance =
	    sizeof (jnlDL_Level_Descriptions) / sizeof (jnlDL_Description_t);

	/*
	 * Point to the highest description, and the one in the middle.
	 * This presumes at least one item in the descriptions!
	 */
	jnlDL_highest	= &jnlDL_Level_Descriptions[distance - 1];
	jnlDL		= &jnlDL_Level_Descriptions[(distance /= 2) - 1];

	/*
	 * Probe for a matching level.
	 */
	while (jnlDL->level != level) {

		/*
		 * Move half the distance each time.
		 */
		jnlDL_prev = jnlDL;
		distance   = (distance + 1) / 2;
		jnlDL	  += (jnlDL->level > level ? -distance : distance);

		/*
		 * Keep it within the table.
		 */
		if (jnlDL > jnlDL_highest) {
		    jnlDL = jnlDL_highest;

		} else if (jnlDL < jnlDL_Level_Descriptions) {
		    jnlDL = jnlDL_Level_Descriptions;

		} /* if (jnlDL > jnlDL_highest) {...} else if (...) {...} */

		/*
		 * If the pointer did not move, then we're bound to one end of
		 * the table. Just return to whichever we're bound.
		 */
		if (jnlDL == jnlDL_prev) {

			return (jnlDL);

		} /* if (jnlDL == jnlDL_prev) {...} */

		/*
		 * If the distance is only one, then we might be about to
		 * ocilate between two items because there is not an exact
		 * match in the table. If so, then return the description of
		 * the higher level. We may ocilate once to get to this state.
		 */
		if (distance == 1) {

			if (jnlDL->level < level &&
			    level < jnlDL_prev->level) {

				return (jnlDL_prev);

			} /* if (jnlDL->level < level && ...) {...} */

		} /* if (distance == 1) {...} */


	} /*  while (jnlDL->level != level) {...} */

	/*
	 * Found a match!
	 */
	return (jnlDL);

} /* jnl_dl_Description_t *jnl_dl_description_fetch (...) {...} */

/*
 *  jnlDL_Description_t *
 *  jnl_dl_level_fetch (char *description);
 *
 *  Description:
 *      jnl_dl_level_fetch() returns a pointer to the description of the
 *	detail level passed using the level to locate the complex data type.
 *
 *  Parameters:
 *      char *description
 *              Input - description of the detail level desired.
 *
 *  Return value:
 *      jnlDL_Description_t * Returns a pointer to a static buffer containing
 *		the complex data type for the detail level description.
 *
 *  Output:
 *      None.
 */
jnlDL_Description_t *
jnl_dl_level_fetch(char *description)
{
	/*
	 * Locals...
	 */
	jnlDL_Description_t	*jnlDL;		/* Pointer to descriptions. */
	jnlDL_Description_t	*jnlDL_highest;	/* Pointer to descriptions. */
	jnlDL_Description_t	*jnlDL_prev;	/* Pointer to descriptions. */
	int			 distance;	/* Traveral size.	*/
	int			 direction;	/* Which way to go...	*/

	/*
	 * How many items are then in the table..
	 */
	distance =
	    sizeof (jnlDL_Description_Levels) / sizeof (jnlDL_Description_t);

	/*
	 * Point to the highest description, and the one in the middle.
	 * This presumes at least one item in the descriptions!
	 */
	jnlDL_highest	= &jnlDL_Description_Levels[distance - 1];
	jnlDL		= &jnlDL_Description_Levels[(distance /= 2) - 1];

	/*
	 * Probe for a matching level.
	 */
	while (direction = strcasecmp(description, jnlDL->description)) {

		/*
		 * Move half the distance each time.
		 */
		jnlDL_prev = jnlDL;
		distance   = (distance + 1) / 2;
		jnlDL	  += (direction < 0 ? -distance : distance);

		/*
		 * Keep it within the table.
		 */
		if (jnlDL > jnlDL_highest) {
		    jnlDL = jnlDL_highest;

		} /* if (jnlDL > jnlDL_highest) {...} */

		if (jnlDL < jnlDL_Description_Levels) {
		    jnlDL = jnlDL_Description_Levels;

		} /* if (jnlDL < jnlDL_Level_Descriptions) {...} */

		/*
		 * If the pointer did not move, then we're bound to one end of
		 * the table. Just return to whichever we're bound.
		 */
		if (jnlDL == jnlDL_prev) {

			return (jnlDL);

		} /* if (jnlDL == jnlDL_prev) {...} */

		/*
		 * If the distance is only one, then we might be about to
		 * ocilate between two items because there is not an exact
		 * match in the table. If so, then return the description of
		 * the higher level. We may ocilate once to get to this state.
		 */
		if (distance == 1) {

			if ((strcasecmp(description, jnlDL->description) < 0)&&
			    (strcasecmp(description,
				jnlDL_prev->description) > 0)) {

				return (jnlDL_prev);

			} /* if (jnlDL->level < level && ...) {...} */

		} /* if (distance == 1) {...} */


	} /*  while (jnlDL->level != level) {...} */

	/*
	 * Found a match!
	 */
	return (jnlDL);

} /* jnl_dl_Description_t *jnl_dl_level_fetch (...) {...} */

/*
 *  int
 *  jnl_log_(char *file__,
 *	int line__,
 *	jnl_DetailLevel_t level,
 *	char *format_string, ...);
 *
 *  Description:
 *      jnl_log() commits a message to the journal file after formatting it
 *	printf() style.
 *
 *      If the level passed is greater than or equal to the value of the
 *      environment variable TJNL_DETAIL, then the string passed will be
 *      committed to the journal via the STC call stf_jnl_msg(). If the level
 *	is less than TJNL_DETAIL, then no error will be returned. For all
 *	intents and purposes the message would have gone to the journal.
 *
 *      All messages logged via this call will include the file name and line
 *      number in the source file of the test whence the call came.
 *
 *	The public interface to this routine is jnl_log().
 *
 *  Parameters:
 *	char *file__
 *		Input - Pointer to a string containing the name of the source
 *		file from which the call came.
 *
 *	int line__
 *		Input - The line number in the source whence the call came.
 *
 *      jnl_DetailLevel_t level
 *		Input - Indicates the detail level of this message.
 *
 *      char *format_string
 *              Input - a printf() style format string by which the va_args
 *              parameters are incorporated into the buffer.
 *
 *      ...
 *              Input - sufficient parameters to satisfy the formatting
 *              directives in format_string.
 *
 *  Return value:
 *      int	Upon successfully committing the buffer to the journal a
 *		value of zero (0) will be returned. If any errors occur,
 *		non-zero will be returned and errno will be set to a
 *		non-zero value by the function, such as write(), which failed.
 *		If jnl_dl_check(level) returns false, then a zero (0) will be
 *		returned as if the message was committed to the journal.
 *
 *  Output:
 *      For detail levels below jnlDL_STACK:
 *
 *      [ - <level> (file: <basename (_FILE_)>, line: <_LINE_>) - ]
 *      <text>
 *
 *      For detail levels of jnlDL_STACK and higher:
 *
 *      [ - <level> - ]
 *      Stack:
 *      - <trace line>
 *      [- <trace line>]
 *      [...]
 *      <Text>
 *
 *      Where:
 *      <level> is the detail level passed to jnl_log().
 *
 *      <basename (_FILE_)> is the base of the file name of the test source
 *              file.
 *
 *      <_LINE_> is the line number in the test source whence the logging call
 *              came.
 *
 *      <text> is the concatenation of all the text strings passed [as va_args]
 *              to jnl_log().
 *
 *      <trace line> is a line of stack track appropriate for the language in
 *              which the test was written.
 */
#if (_STF_JNL_VARIADIC_MACROS >= 1)
int
jnl_vlog_(char *file__,
    int line__,
    jnl_DetailLevel_t level,
    char *format_string,
    va_list args)
{
#else
int
jnl_vlog_(jnl_DetailLevel_t level, char *format_string, va_list args)
{
#endif
	/*
	 * Locals...
	 */
	int	 ret;		/* Just a return value.			*/
	char	 format_buffer[jnlBS_format]; /* Intermediate format string. */
	char	 jnl_buffer[jnlBS_LOG];	/* Buffer to send to journal.	*/
	jnlDL_Description_t *jnlDL_desc;	/* Level description.	*/
	char	*fmt;		/* Primary format string.		*/
	char	*p;		/* For pretty printing the output.	*/
	char	*s;		/* Ditto.				*/
	char	 c;		/* Just a character.			*/

	/*
	 * If the level passed is too high, then there's nothing to do this
	 * time.
	 */
	if (! JNL_DL_CHECK(level)) {
		return (0);

	} /* if (! jnl_dl_check(level)) {...} */

	/*
	 * Create the message header for the journal.
	 */
	jnlDL_desc = jnl_dl_description_fetch(level);

#if (_STF_JNL_VARIADIC_MACROS >= 1)

	if (jnlDL_desc->level == level) {
		fmt = "[ - %s (file: %s, line: %d) - ]\n%s";

	} else {
		fmt = "[ - ~%s (file: %s, line: %d) - ]\n%s";

	} /* if (jnlDL_desc->level != level) {...} */

	ret = snprintf(format_buffer,
	    sizeof (format_buffer),
	    fmt,
	    jnlDL_desc->description,
	    file__,
	    line__,
	    format_string);
#else
	if (jnlDL_desc->level == level) {
		fmt = "[ - %s - ]\n%s";

	} else {
		fmt = "[ - ~%s - ]\n%s";

	} /* if (jnlDL_desc->level != level) {...} */

	ret = snprintf(format_buffer,
	    sizeof (format_buffer),
	    fmt,
	    jnlDL_desc->description,
	    format_string);
#endif
	/*
	 * Finally, initialize the vargs list and put the caller's data into
	 * the buffer.
	 */
	ret = vsnprintf(jnl_buffer, sizeof (jnl_buffer), format_buffer, args);
	if (ret < 0) {
		jnl_internal_error("jnl_log_():\n"
		    "vsnprintf(%p, %d, %p, ...) returned %d.\n"
		    "Could not format journal message.",
		    jnl_buffer,
		    sizeof (jnl_buffer),
		    format_buffer,
		    ret);

		return (-1);

	} /* if (vsnprintf(jbuffer, args) < 0) {...} */

	/*
	 * Finally, commit this beast to the journal file!
	 * In order to make this look pretty in the journal, I need to scan
	 * for new line characters and send each line individually.
	 */
	for (s = p = jnl_buffer; *p; ++s) {
		if (*s == '\n' || *s == '\0') {

			/*
			 * If they point to the same place, then we have
			 * either adjacent \n characters or we started with
			 * a \n character.
			 */
			if (s == p) {
				(void) stf_jnl_msg(" ");

			} else /* if (s != p) */ {
				c  = *s;
				*s = '\0';
				(void) stf_jnl_msg(p);
				*s = c;

			} /* if (s == p) {...} else {...} */

			/*
			 * Whatever we printed, advance the scanning pointer
			 * past it, and update the printing pointer to the
			 * new location.
			 */
			p = s + (*s == '\0' ? 0 : 1);

		} /* if (*s == '\n') {...} */

	} /* for (fmt = jnl_buffer; *fmt; ++fmt) {...} */

	/*
	 * Finally, put one blank line after the message for legibility.
	 */
	(void) stf_jnl_msg(" ");

	/*
	 * Guess it worked...
	 */
	return (0);

} /* int jnl_vlog_ (jnl_DetailLevel_t level, ...) {...} */

#if (_STF_JNL_VARIADIC_MACROS >= 1)

int
jnl_log_(char *file__,
    int line__,
    jnl_DetailLevel_t level,
    char *format_string, ...)
{
	va_list	args;
	int	ret;

	va_start(args, format_string);
	ret = jnl_vlog_(file__, line__, level, format_string, args);
	va_end(args);

	return (ret);

} /* int jnl_log_ (jnl_DetailLevel_t level, ...) {...} */
#else
int
jnl_log_(jnl_DetailLevel_t level, char *format_string, ...)
{
	va_list	args;
	int	ret;

	va_start(args, format_string);
	ret = jnl_vlog_(level, format_string, args);
	va_end(args);

	return (ret);

} /* int jnl_log_(jnl_DetailLevel_t level, char *format_string, ...) {...} */
#endif

/*
 *  int
 *  jnl_result_ (char *file__, int line__, int resultcode);
 *
 *  Description:
 *	jnl_RESULT() sends a jnlDL_RESULT level message to the journal,
 *	presumably indicating the result of the test case. This is for
 *	informational purposes only and is not required of any test case.
 *	STC components exterior to the test case determine the actual
 *	result of the test based on program exit status. Consequently, there
 *	is a small possibility that a message generated through this call may
 *	not agree with the actual program exit status. When such inconsistency
 *	occurrs, the test will be considered not to have passed.
 *
 *  Parameters:
 *	char *file__
 *		Input - Pointer to a string containing the name of the source
 *		file from which the call came.
 *
 *	int line__
 *		Input - The line number in the source whence the call came.
 *
 *	int resultcode
 *		Input - STC specific result code indicating the assertion
 *		verification success or failure.
 *
 *  Return value:
 *	int	Same return values as jnl_log().
 *
 *  Output:
 *	Following the formats described in jnl_log(), the text portion of the
 *	message will be formatted as follows:
 *
 *	- RESULT: <code word>
 *
 *	Where:
 *	<code word> is the English text of corresponding to the STC specific
 *	result code.
 *
 */
#if (_STF_JNL_VARIADIC_MACROS >= 1)
int
jnl_result_(char *file__, int line__, int resultcode)
{
#else
int
jnl_result_(int resultcode)
{
#endif
	/*
	 * Locals...
	 */
	int	ret;		/* Just a return value.			*/

	/*
	 * Make sure the result code is within the table of words.
	 */
	if (resultcode >= STF_MAX_RESULTS) {
		resultcode = STF_OTHER;

	} /* if (resultcode > STF_MAX_RESULTS) {...} */

	/*
	 * Make sure the result is valid.
	 */
	if (resultcode < STF_PASS) {
		ret = jnl_DIAGNOSTIC(jnl_OPERATION("jnl_RESULT(%d)",
		    resultcode),
		    jnl_EXPECTED("%d <= result code <= %d.",
			STF_PASS,
			STF_OTHER),
		    jnl_ERROR("Result code out of range."),
		    jnl_ACTION("Report result of NORESULT."));

		if (ret != 0) {
			jnl_internal_error("jnl_result_(... %d)\n"
			    "jnl_DIAGNOSTIC() returned %d",
			    resultcode,
			    ret);

		} /* if (ret != 0) {...} */

#if (_STF_JNL_VARIADIC_MACROS >= 1)

		if (ret = jnl_result_(file__, line__, STF_NORESULT)) {
			jnl_internal_error("jnl_result_(..., %d)\n"
			    "jnl_result_(..., NORESULT) returned %d",
			    ret);

#else

		if (ret = jnl_result_(STF_NORESULT)) {
			jnl_internal_error("jnl_result_(..., %d)\n"
			    "jnl_result_(..., NORESULT) returned %d",
			    ret);

#endif

		} /* if (ret = jnl_result_(...)) {...} */

		return (-1);

	} /* if (resultcode < STF_PASS) {...} */

	/*
	 * Construct the result message.
	 */
#if (_STF_JNL_VARIADIC_MACROS >= 1)

	return (jnl_log_(file__,
	    line__,
	    jnlDL_RESULT,
	    "RESULT: %s",
	    result_tbl[resultcode]));

#else

	return (jnl_log_(jnlDL_RESULT, "RESULT: %s", result_tbl[resultcode]));

#endif

} /* int jnl_result_ (char *file__, int line__, int resultcode) {...} */

/*
 *  int
 *  jnl_printf(char *format_string, ...);
 *  int
 *  jnl_PROGRESS(char *format_string, ...);
 *  int
 *  jnl_VERBOSE(char *format_string, ...);
 *
 *  Description:
 *	These functions accept format strings suitable for printf() and send
 *	the resulting string to the journal. jnl_printf() and jnl_PROGRESS()
 *	are synonymous. They both send jnlDL_PROGRESS level messages.
 *	jnl_VERBOSE() sends jnlDL_VERBOSE level messages.
 *
 *  Parameters:
 *      char *format_string
 *              Input - a printf() style format string by which the va_args
 *              parameters are incorporated into the buffer.
 *
 *      ...
 *              Input - sufficient parameters to satisfy the formatting
 *              directives in format_string.
 *
 *  Return value:
 *	int	Same return values as jnl_LOG().
 *
 *  Output:
 *	Following the formats specified in jnl_LOG(), the strings passed will
 *	comprise the <text> of the message sent to the journal. These functions
 *	add no additional formatting.
 */
#if (_STF_JNL_VARIADIC_MACROS < 1)

NOTE(PRINTFLIKE(1))
int
jnl_PROGRESS(char *format_string, ...)
{
	int	ret;
	va_list	args;

	va_start(args, format_string);
	ret = jnl_vlog_(jnlDL_PROGRESS, format_string, args);
	va_end(args);

	return (ret);

} /* int jnl_PROGRESS(char *format_string, ...) {...} */

NOTE(PRINTFLIKE(1))
int
jnl_VERBOSE(char *format_string, ...)
{
	int	ret;
	va_list	args;

	va_start(args, format_string);
	ret = jnl_vlog_(jnlDL_VERBOSE, format_string, args);
	va_end(args);

	return (ret);

} /* int jnl_VERBOSE(char *format_string, ...) {...} */

#endif

/*
 *  char *
 *  jnl_format_messge_ (jnl_buffer_index_t index, char *format_string, ...);
 *
 *  Description:
 *      Returns the address of a thread static buffer containing preformatted
 *	text with a keyword prefix corresponding to the name of the message
 *	index passed.
 *
 *  Parameters:
 *	char *file__
 *		Input - Pointer to a string containing the name of the source
 *		file from which the call came.
 *
 *	int line__
 *		Input - The line number in the source whence the call came.
 *
 *      jnl_buffer_index_t index
 *		Input - Message index into jnl_Descriptions[].
 *
 *      char *format_string
 *              Input - a printf() style format string by which the va_args
 *              parameters are incorporated into the buffer.
 *
 *      ...
 *              Input - sufficient parameters to satisfy the formatting
 *              directives in format_string.
 *
 *  Return value:
 *      char *  Returns the address of a static buffer containing the formatted
 *              text. Each function has its own buffer and is reentrant at
 *              the thread level.
 *              This may return (char *)NULL if the buffer could not be
 *              allocated from the heap.
 *
 *	Buffer contents:
 *      <Function>:
 *      - <text>
 *
 *      Where:
 *      <Function> is one of the following:
 *      	"Operation"     for jnl_OPERATION(),
 *              "Expected"      for jnl_EXPECTED(),
 *              "Error"         for jnl_ERROR(),
 *              "Action"        for jnl_ACTION().
 *
 *      <text> is the result of vsnprintf() of format_string into the buffer.
 *	Any strings longer than the buffer will be truncated without error.
 *
 *  Output:
 *      None.
 */
NOTE(PRINTFLIKE(2))
char *
jnl_vformat_message_(jnl_buffer_index_t index,
    char *format_string,
    va_list args)
{
	/*
	 * Locals...
	 */
	char	 format_buffer[jnlBS_format];	/* Intermediate buffer.	*/
	char	*message;	/* Thread specific mesage buffer.	*/
	int	 ret;		/* Just a return value.			*/

	/*
	 * Fetch the message buffer.
	 */
	message = _jnl_buffer_fetch(thr_self(), index);
	if (message == (char *)NULL) {

		/*
		 * Huh? Wonder why that didn't work? Can't do anything without
		 * a buffer.
		 */
		jnl_internal_error("jnl_format_message_():\n"
		    "_jnl_buffer_fetch(%d, %d) failed for %s buffer.",
		    thr_self(),
		    index,
		    jnl_message_title[index]);

		return ((char *)NULL);

	} /* if (message == (char *)NULL) {...} */

	/*
	 * Construct the title in the format buffer.
	 */
	ret = snprintf(format_buffer,
	    sizeof (format_buffer),
	    "%s:\n- %s",
	    jnl_message_title[index],
	    format_string);

	if (ret < 0) {

		/*
		 * Well, that was rude!
		 */
		jnl_internal_error("jnl_format_message_():\n"
		    "snprintf() failed and returned %d.",
		    ret);

		return ((char *)NULL);

	} /* if (ret < 0) {...} */

	/*
	 * Finally, build the caller's message.
	 */
	ret = vsnprintf(message,
	    jnl_message_buffer_size[index],
	    format_buffer,
	    args);

	if (ret < 0) {

		/*
		 * Bad juju! Caller's format string failed for some reason.
		 */
		jnl_internal_error("jnl_format_message_()\n"
		    "vsnprintf(%p, %d, %p, ...) returned %d.\n"
		    "Could not format message %d.",
		    message,
		    jnl_message_buffer_size[index],
		    format_buffer,
		    ret,
		    index);

		return ((char *)NULL);

	} /* if (ret < 0) {...} */

	/*
	 * Return the newly formatted message.
	 */
	return (message);

} /* char *jnl_vformat_message_ (...) {...} */

char *
jnl_format_message_(jnl_buffer_index_t index, char *format_string, ...)
{
	char	*ret;
	va_list	args;

	va_start(args, format_string);
	ret = jnl_vformat_message_(index, format_string, args);
	va_end(args);

	return (ret);

} /* jnl_format_message_(jnl_buffer_index_t index, ...) {...} */

#if (_STF_JNL_VARIADIC_MACROS < 1)

NOTE(PRINTFLIKE(1))
char *
jnl_operation_(char *fmt, ...)
{
	char	*ret;
	va_list	 args;

	va_start(args, fmt);
	ret = jnl_vformat_message_(jnlBI_OPERATION, fmt, args);
	va_end(args);

	return (ret);

} /* char *jnl_operation_(const char * fmt, ...) {...} */

NOTE(PRINTFLIKE(1))
char *
jnl_expected_(char *fmt, ...)
{
	char	*ret;
	va_list	 args;

	va_start(args, fmt);
	ret = jnl_vformat_message_(jnlBI_EXPECTED, fmt, args);
	va_end(args);

	return (ret);

} /* char *jnl_expected_(const char * fmt, ...) {...} */

NOTE(PRINTFLIKE(1))
char *
jnl_error_(char *fmt, ...)
{
	char	*ret;
	va_list	 args;

	va_start(args, fmt);
	ret = jnl_vformat_message_(jnlBI_ERROR, fmt, args);
	va_end(args);

	return (ret);

} /* char *jnl_error_(const char * fmt, ...) {...} */

NOTE(PRINTFLIKE(1))
char *
jnl_action_(char *fmt, ...)
{
	char	*ret;
	va_list	 args;

	va_start(args, fmt);
	ret = jnl_vformat_message_(jnlBI_ACTION, fmt, args);
	va_end(args);

	return (ret);

} /* char *jnl_action_(const char * fmt, ...) {...} */

#endif
