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

#pragma ident	"@(#)stf_jnl_assert_end.c	1.3	07/05/04 SMI"

/*
 *  stf_jnl_assert_end.c
 */

#include <stf_impl.h>

int
main(int argc, char *argv[])
{
	unsigned int result;

	if (argc != 2) {
		(void) fprintf(stderr, "usage: %s result\n", argv[0]);
		exit(1);
	}
	result = atoi(&argv[1][0]);

	stf_jnl_assert_end_pid(getppid(), result);
	return (0);
}
