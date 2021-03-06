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

#include <stdio.h>
#include <sys/socket.h>
#include <errno.h>

#include <stf.h>
#include <mstf.h>

#define	BUF_SIZE 1024

/*
 * This is a wrapper to call mstf_getvar from libmstf.
 */
int
main(int argc, char *argv[])
{
	char result[BUF_SIZE];

	if (argc != 2) {
		(void) printf("Usage: mstf_getvar <variable>\n");
		return (STF_UNRESOLVED);
	}
	if (mstf_getvar(argv[1], result, BUF_SIZE) == STF_PASS) {
		(void) printf(result);
		return (STF_PASS);
	}
	return (STF_UNRESOLVED);
}
