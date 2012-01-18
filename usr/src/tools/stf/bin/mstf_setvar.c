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

/*
 * This is a wrapper to call mstf_setvar from libmstf.
 */
int
main(int argc, char *argv[])
{
	if (argc != 3) {
		(void) printf("Usage: mstf_setvar <variable> <value>\n");
		return (STF_UNRESOLVED);
	}

	return (mstf_setvar(argv[1], argv[2]));
}
