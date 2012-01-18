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

#ifndef _MSTF_H
#define	_MSTF_H

#ifdef __cplusplus
extern "C" {
#endif

#include <inttypes.h>

#define	MSTF_SYNC_PORT "9100"
#define	MSTF_BUFLEN 128

int mstf_sync(const char *label);
int mstf_setvar(const char *var_name, const char *value);
int mstf_getvar(const char *var_name, char *result, int result_len);

#ifdef __cplusplus
}
#endif

#endif /* _MSTF_H */
