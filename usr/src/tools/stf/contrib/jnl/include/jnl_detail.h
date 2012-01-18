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

#ifndef _JNL_DETAIL_H
#define	_JNL_DETAIL_H

#ifdef __cplusplus
extern "C" {
#endif

#include <limits.h>

/*
 *      jnl_DetailLevel_t - enumerated typedef.
 *
 *      The jnl_* functions use these levels to determine whether or not the
 *      text of a message should be committed ot the journal. If the value of
 *      the environment variable TJNL_DETAIL is greater than or equal to the
 *      value of the level passed with the message, then then message will be
 *      sent to the journal.
 *
 *      Test development need not focus on message levels. Generally there are
 *      functions which log specific format messages and use the correct level
 *      internally. Only when specially formatted messages are required must
 *      the general purpose logging function jnl_Log() be used and a level
 *      explicitly named.
 *
 *      ASSERTION level has been included for uniqueness. The jnl_ASSERTION()
 *      function uses this level to log the text of the assertion. These
 *      messages will always be placed in the journal.
 *
 *      RESULT level has been included for uniqueness. The jnl_RESULT()
 *      function uses this level to log the text of the result message. These
 *      level messages will always be sent to the journal.
 *
 *      DIAGNOSTIC level messages must always be logged. Generally these
 *      should be generated for any error conditions that occur whether or
 *      not the condition effects assertion verification. This is the level
 *      used by the jnl_DIAGNOSTIC() function.
 *
 *      PROGRESS level messages simply state milestones the test has
 *      accomplished during execution. If a test takes particularly long to
 *      execute, then it should include several progress messages
 *      demonstrating that it has not hung. This is the default level of
 *      logging information expected, so such messages should not be annoyingly
 *      numerous. This is the level used by the jnl_PROGRESS() function.
 *
 *      VERBOSE level messages are simply more progress messages -- similar
 *      in content to PROGRESS level messages, but more numerous throughout
 *      the test. These may be borderline annoying in volume. This is the
 *      level used by the jnl_VERBOSE() function.
 *
 *      STACK level includes a stack trace leading up to the logging call
 *      followed by the message content. The underlying logging function adds
 *      the stack trace automatically. There is no need to pepper test code
 *      with STACK level messages. The purpose of this level is to inform the
 *      logging facilities that stack traces should be added to all messages
 *      sent to the journal. There is no function specific to generating this
 *      level of message.
 *
 *      ENCYCLOPEDIC messages have the same format as stack messages. They
 *      include a stack trace and a message. However, they may be
 *      be more numerous in the test than would be practical for normal logging
 *      behavior. In particular, these messages may be accomplished by first
 *      checking the detail level (via jnl_dl_check(jnlDL_Encyclopedic)) and
 *	executing additional code to gather more information for the journal.
 *	There is no function specific to generating this level of message.
 */
typedef enum jnl_DetailLevel {
	jnlDL_ASSERTION = (INT_MIN),		 /* What's being tested. */
	jnlDL_RESULT	= (jnlDL_ASSERTION + 1), /* PASS, FAIL, etc.	 */
	jnlDL_DIAGNOSTIC = (jnlDL_RESULT + 1),	 /* Error messages.	 */
	jnlDL_PROGRESS	= (0),			 /* Milestones (default). */
	jnlDL_ENCYCLOPEDIC = (INT_MAX),		 /* Everything...	 */
	jnlDL_STACK	= (jnlDL_ENCYCLOPEDIC / 2), /* Milestones w/ stack */
	jnlDL_VERBOSE	= (jnlDL_STACK / 2)	 /* Almost everything... */
} jnl_DetailLevel_t;

/*
 *	jnl_DetailLevel_Description_t - complex data type
 *
 *	The jnl_* functions use these descriptions to label the detail level of
 *	each message sent to the journal.
 */
typedef struct jnlDL_Description {
	jnl_DetailLevel_t	level;
	char			*description;
} jnlDL_Description_t;

/*
 * A constant containing the name of the environment variable used for the
 * detail level.
 */
extern const char jnlDL_ENV_NAME[];

#ifdef __cplusplus
}
#endif

#endif /* _JNL_DETAIL_H */
