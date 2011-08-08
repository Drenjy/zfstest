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

#ifndef _JNL_PROTO_H
#define	_JNL_PROTO_H

#pragma ident	"@(#)jnl_proto.h	1.7	07/04/12 SMI"

#ifdef __cplusplus
extern "C" {
#endif

#include <stdarg.h>

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
 *
 */
jnl_DetailLevel_t
jnl_dl_fetch(void);

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
 *
 */
int
jnl_dl_check(jnl_DetailLevel_t level);

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
 *
 */
jnlDL_Description_t *
jnl_dl_description_fetch(jnl_DetailLevel_t level);

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
 *
 */
jnlDL_Description_t *
jnl_dl_level_fetch(char *description);

/*
 *  int
 *  jnl_LOG(jnl_DetailLevel_t level, ...);
 *
 *  Description:
 *      jnl_LOG() commits a message to the journal file.
 *
 *      If jnl_dl_check(level) returns true, then the strings passed will be
 *      committed to the journal via the STC call stf_jnl_msg(). If
 *	jnl_dl_check(level) returns false, the this function simply returns
 *	without error.
 *
 *      All messages logged via this call will include the file name and line
 *      number in the source file of the test whence the call came.
 *
 *  Parameters:
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

#define	jnl_LOG(...) (jnl_log_(__FILE__, __LINE__, __VA_ARGS__))

int
jnl_log_(char *file__,
    int line__,
    jnl_DetailLevel_t level,
    char *format_string, ...);

#else

#define	jnl_LOG	jnl_log_

int
jnl_log_(jnl_DetailLevel_t level, char *format_string, ...);

#endif


/*
 *  int
 *  jnl_ASSERTION(char *assertion, char *interfaces);
 *
 *  Description:
 *	jnl_ASSERTION() generates a jnlDL_ASSERTION level message in the
 *	journal containing the name of the assertion, the text of the assertion
 *	statement, and the list of target interfaces. The assertion name is
 *	presumed to be the name of the program file currently executing. This
 *	API creates a copy in the journal of the information STC requires to
 *	be in the ".spec" file, but it does NOT create the ".spec" file itself.
 *
 *  Parameters:
 *	char *assertion
 *		Input - Null terminated string containing the assertion
 *		statement according to the STC requirements for the content of
 *		the ".spec" file.
 *
 *	char *interfaces
 *		Input - Null terminated string of the target interfaces of this
 *		test according to the STC requirements for the content of the
 *		".spec" file.
 *
 *  Return value:
 *	int	Same return values as jnl_LOG().
 *
 *  Output:
 *	Following the formats described in jnl_log(), the text portion of the
 *	message will be formatted as follows:
 *
 *	ASSERTION:
 *	- <name>
 *	DESCRIPTION:
 *	- <assertion statement>
 *	INTERFACES:
 *	- <interface list>
 *
 *	Where:
 *	<name> is the assertion name (program file).
 *
 *	<assertion statement> is the text from the assertion parameter.
 *
 *	<interface list> is the text from the interfaces parameter.
 *
 */
#define	jnl_ASSERTION(as, in) (jnl_LOG(jnlDL_ASSERTION, \
	"ASSERTION:\n" \
	"- %s\n" \
	"DESCRIPTION:\n" \
	"- %s\n" \
	"INTERFACES:\n" \
	"- %s", \
	__FILE__, \
	as, \
	in))


/*
 *  int
 *  jnl_ASSERT(char *assert_id, char *assertion);
 *
 *  Description:
 *	jnl_ASSERT() generates a jnlDL_ASSERTION level message in the
 *	journal containing the assertion name and the text of the assertion
 *	statement, both passed in through the command line.
 *
 *  Parameters:
 *	char *assert_id
 *		The assertion identifier.  This is the value of "ID:"
 *		in the assertion document.
 *
 *	char *assertion
 *		The assertion text.  This is the value of "DESCRIPTION:"
 *		in the assertion document.
 *
 *  Return value:
 *	int	Same return values as jnl_LOG().
 *
 *  Output:
 *	Following the formats described in jnl_log(), the text portion of the
 *	message will be formatted as follows:
 *
 *	ASSERTION ID:
 *	- <name>
 *	DESCRIPTION:
 *	- <assertion statement>
 *
 *	Where:
 *	<name> is the assertion identifier.
 *
 *	<assertion statement> is the text from the assertion parameter.
 *
 *	<interface list> is the text from the interfaces parameter.
 *
 *  Note - this macro is very similar to jnl_ASSERTION.  The difference is
 *	that this macro report the assertion identifier and does not
 *	assume this is equivalent to the filename.  Additionally, it does
 *	not require the interfaces interface.  Finally, it has a
 *	corresponding ksh and Perl verion.
 */

#define	jnl_ASSERT(id, as) (jnl_LOG(jnlDL_ASSERTION, \
	"ASSERTION ID:\n" \
	"- %s\n" \
	"DESCRIPTION:\n" \
	"- %s", \
	id, \
	as))

/*
 *  int
 *  jnl_RESULT(int resultcode);
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
 *	int resultcode
 *		Input - STC specific result code indicating the assertion
 *		verification success or failure.
 *
 *  Return value:
 *	int	Same return values as jnl_log().
 *
 *  Output:
 *	Following the formats described in jnl_LOG(), the text portion of the
 *	message will be formatted as follows:
 *
 *	RESULT: <code word>
 *
 *	Where:
 *	<code word> is the English text of corresponding to the STC specific
 *	result code.
 *
 */
#if (_STF_JNL_VARIADIC_MACROS >= 1)

#define	jnl_RESULT(rc) (jnl_result_(__FILE__, __LINE__, rc))

int
jnl_result_(char *file__, int line__, int resultcode);

#else

#define	jnl_RESULT jnl_result_

int
jnl_result_(int resultcode);

#endif

/*
 *  int
 *  jnl_printf(char *format_string, ...);
 *  int
 *  jnl_PROGRESS(char *format_string, ...);
 *  int
 *  jnl_VERBOSE(char *format_string, ...);
 *  int
 *  jnl_DIAG(char *format_string, ...);
 *
 *  Description:
 *	These functions accept format strings suitable for printf() and send
 *	the resulting string to the journal. jnl_printf() and jnl_PROGRESS()
 *	are synonymous. They both send jnlDL_PROGRESS level messages.
 *	jnl_VERBOSE() sends jnlDL_VERBOSE level messages, and jnl_DIAG
 *	sends jnlDL_DIAGNOSTIC level messages.
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
 *
 */
#define	jnl_printf jnl_PROGRESS

#if (_STF_JNL_VARIADIC_MACROS >= 1)

#define	jnl_PROGRESS(...) (jnl_LOG(jnlDL_PROGRESS, __VA_ARGS__))
#define	jnl_VERBOSE(...) (jnl_LOG(jnlDL_VERBOSE, __VA_ARGS__))
#define	jnl_DIAG(...) (jnl_LOG(jnlDL_DIAGNOSTIC, __VA_ARGS__))

#else

#define	jnl_PROGRESS	jnl_progress_
#define	jnl_VERBOSE	jnl_verbose_
#define	jnl_DIAG	jnl_diagnostic_

#endif

/*
 *  int
 *  jnl_DIAGNOSTIC(...);
 *
 *  Description:
 *	jnl_DIAGNOSTIC() send the collection of strings passed to the journal
 *	at jnlDL_DIAGNOSTIC level.
 *
 *  Parameters:
 *      ...
 *              Input - A va_arg list of char *s pointing to null terminated
 *		strings. These will be concatenated into a single buffer and
 *		committed to the journal..
 *
 *  Return value:
 *	int	Same return values as jnl_LOG().
 *
 *  Output:
 *	Following the formats specified in jnl_LOG(), the strings passed will
 *	comprise the <text> of the message sent to the journal. This function
 *	adds no additional formatting.
 *
 */
#define	jnl_DIAGNOSTIC(op, exp, err, act) (jnl_LOG(jnlDL_DIAGNOSTIC, \
	"%s\n%s\n%s\n%s", \
	op, \
	exp, \
	err, \
	act))

/*
 * Enumeration of indices to message buffers for a given thread. Used
 * specifically by jnl_OPERATION(), jnl_EXPECTED(), jnl_ERROR(), and
 * jnl_ACTION() to call jnl_format_message_().
 */
typedef enum jnl_buffer_index {		/* Journal message buffer indices. */
	jnlBI_MIN_	   = 0,
	jnlBI_OPERATION	= jnlBI_MIN_,	/* operation message.	*/
	jnlBI_EXPECTED	/* = 1 */,	/* Expected message.	*/
	jnlBI_ERROR	/* = 2 */,	/* Error message.	*/
	jnlBI_ACTION	/* = 3 */,	/* Action message.	*/
	jnlBI_MAX_	/* = 4 */	/* Maximum index...	*/

} jnl_buffer_index_t;

/*
 *  char *
 *  jnl_format_messge_ (jnl_buffer_index_t index, char *format_string, ...);
 *
 *  Description:
 *      Returns the address of a thread static buffer containing preformatted
 *	text with a keyword prefix corresponding to the name of the message
 *	index passed. This is used exclusively by jnl_OPERATION(),
 *	jnl_EXPECTED(), jnl_ERROR(), and jnl_ACTION().
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
 *      	"Operation"     for jnl_operation(),
 *              "Expected"      for jnl_expected(),
 *              "Error"         for jnl_error(),
 *              "Action"        for jnl_action().
 *
 *      <text> is the result of vsnprintf() of format_string into the buffer.
 *	Any strings longer than the buffer will be truncated without error.
 *
 *  Output:
 *      None.
 *
 */
char *
jnl_format_message_(jnl_buffer_index_t index, char *format_string, ...);

char *
jnl_vformat_message_(jnl_buffer_index_t index,
    char *format_string,
    va_list args);

/*
 *  char *
 *  jnl_OPERATION(char *format_string, ...);
 *  char *
 *  jnl_EXPECTED(char *format_string, ...);
 *  char *
 *  jnl_ERROR(char *format_string, ...);
 *  char *
 *  jnl_ACTION(char *format_string, ...);
 *
 *  Description:
 *      Each function returns the address of a static buffer containing
 *      preformatted text with a keyword prefix corresponding to the name of
 *      the function called.
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
 *
 */
#if (_STF_JNL_VARIADIC_MACROS >= 1)

#define	jnl_OPERATION(...) (jnl_format_message_(jnlBI_OPERATION, __VA_ARGS__))
#define	jnl_EXPECTED(...)  (jnl_format_message_(jnlBI_EXPECTED,	 __VA_ARGS__))
#define	jnl_ERROR(...)	   (jnl_format_message_(jnlBI_ERROR,	 __VA_ARGS__))
#define	jnl_ACTION(...)	   (jnl_format_message_(jnlBI_ACTION,	 __VA_ARGS__))

#else

#define	jnl_OPERATION	jnl_operation_
#define	jnl_EXPECTED	jnl_expected_
#define	jnl_ERROR	jnl_error_
#define	jnl_ACTION	jnl_action_

char *
jnl_operation_(char *fmt, ...);

char *
jnl_expected_(char *fmt, ...);

char *
jnl_error_(char *fmt, ...);

char *
jnl_action_(char *fmt, ...);

#endif

#ifdef __cplusplus
}
#endif

#endif /* _JNL_PROTO_H */
