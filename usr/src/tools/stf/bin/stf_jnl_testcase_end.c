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

/*
 *   stf_jnl_testcase_end.c
 */

#include <stf_impl.h>

int
main(int argc, char *argv[])
{
	unsigned int status;
	char **asrt;

	if (argc != 3) {
		(void) fprintf(stderr, "usage: %s assertion status\n", argv[0]);
		exit(1);
	}

	status = atoi(&argv[2][0]);
	/*
	 * This status is from the Bourne shell (better be!).  The status
	 * looks like this:
	 *	0..127  normal exit; value is exit status
	 *	128..	process terminated due to signal # n - 128
	 * This isn't quite what jnl_asrt_end() is expecting, since it
	 * wants the value from wait().  So if this is a normal exit, we
	 * have to shift the status to where wait() would have put it.
	 */
	if (status <= 127)
		status <<= 8;

	asrt = &(argv[1]);
	stf_jnl_testcase_end(asrt[0], getppid(), status);
	return (0);
}
