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
#include <stdlib.h>
#include <errno.h>
#include <signal.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

static void print_usage(void);

int
main(int argc, char **argv)
{
	int pid;
	struct stat statbuf;

	/*
	 * parse and validate command line args
	 */
	if (argc < 2) {
		print_usage();
		exit(1);
	}

	if (stat(argv[1], &statbuf) != 0) {
		(void) fprintf(stderr,
			"FATAL ERROR: pathname %s is not valid\n", argv[1]);
		exit(1);
	}

	/*
	 * Fork off child to exec the daemon and then exit
	 */
	if ((pid = fork()) == 0) {

		(void) close(0);
		(void) close(1);
		(void) close(2);

		(void) setsid();

		(void) execv(argv[1], &argv[1]);
	} else if (pid < 0) {
		(void) fprintf(stderr,
			"FATAL ERROR: Unable to fork process: errno = %d\n",
			errno);
		exit(1);
	} else {
		(void) printf("Successfully daemonized %s\n", argv[1]);
	}
	return (0);
}

static void
print_usage(void)
{
	(void) fprintf(stderr, "\nUsage: daemonize <pathname> <args>\n\n");
}
