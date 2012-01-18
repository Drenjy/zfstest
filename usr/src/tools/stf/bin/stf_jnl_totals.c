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
 * stf_jnl_totals differs from the function because you can't pass
 * an array from a script, so each individual result and count
 * is printed on a journal totals line
 */

#include <stf_impl.h>
#include <string.h>

int
main(int argc, char *argv[])
{
	unsigned int result_array[STF_MAX_RESULTS];
	unsigned int i, pid, result_count, res_match = 0;
	char *test_name, *result_string, *progname;

	progname = argv[0];
	if (((argc % 2) != 0) || (argc < 3)) {
		(void) fprintf(stderr,
			"usage: %s subid {result_name count ...}\n", progname);
		(void) fprintf(stderr, "example: %s sub1 PASS 10 FAIL 3\n",
			progname);
		exit(1);
	}

	/* initialize entire array to 0 */
	for (i = 0; i < STF_MAX_RESULTS; i++) {
		result_array[i] = 0;
	}

	/* set count value in array for that particular result code */
	--argc;
	test_name = *++argv;
	while (--argc > 0) {
		result_string = *++argv;
		--argc;
		result_count = atoi(*++argv);
		res_match = 0;
		for (i = 0; i < STF_MAX_RESULTS; i++) {
			if ((strcmp(result_string, result_tbl[i])) == 0) {
				result_array[i] = result_count;
				res_match = 1;
			}
		}
		if (res_match == 0) {
			(void) fprintf(stderr,
				"%s: %s is not a valid result name\n",
				progname, result_string);
			exit(1);
		}

	}
	pid = getppid();
	stf_jnl_totals_pid(pid, test_name, (int *)result_array);
	return (0);
}
