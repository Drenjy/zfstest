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

#pragma ident	"@(#)stf_gosu.c	1.5	07/04/12 SMI"

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <stf.h>

int
main(int argc, char *argv[])
{
	char **arg;

	if (argc <= 1)
		return (STF_UNRESOLVED);

	arg = &argv[1];
	if (setuid(0)) {
		(void) fprintf(
		    stderr,
		    "**** Error: Failed to become a privileged user.!\n");
		return (STF_UNRESOLVED);

	}
	(void) execvp(arg[0], arg);
	return (STF_UNRESOLVED);
}
