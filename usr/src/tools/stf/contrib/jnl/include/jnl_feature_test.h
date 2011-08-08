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

#ifndef	_JNL_FEATURE_TEST_H
#define	_JNL_FEATURE_TEST_H

#pragma ident	"@(#)jnl_feature_test.h	1.3	07/04/12 SMI"

/*
 * Compiler version dependencies.
 *
 * Implementation of these journal API extensions require SO/IEC 9899:1999
 * C99 variadic macro features.  These were included in SunPro Workshop C
 * compiler version 6.1 or later (unless C89 was requested). These are also
 * supported in GNUC version 3 or later regardless of C standard.
 *
 * _STF_JNL_VARIADIC_MACROS is just a nickname for that comparison.
 *
 * Compiler switch -D_STF_JNL_VARIADIC_MACROS=0 will override this check.
 *
 * Given that all of our current compilers support this (and likely to
 * continue to) we will set STF_JNL_VARIADIC_MACROS to '1'. If in the
 * future something changes we can add the appropriate #ifdefs
 *
 */

#ifdef	__cplusplus
extern "C" {
#endif

#define	_STF_JNL_VARIADIC_MACROS	1

#ifdef	__cplusplus
}
#endif

#endif	/* _JNL_FEATURE_TEST_H */
