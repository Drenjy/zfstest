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

#pragma ident	"@(#)generate.c	1.8	07/04/12 SMI"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>

static const char usage[] =
"\n"
"Usage:	generate <prefix> <count> <suffix>\n"
"\n"
"Where:\n"
"	<prefix>	is a string to prefix on each line.\n"
"	<count>		is a count of the number of data to generate.\n"
"	<suffix>	is a string to append to each line.\n"
"\n"
"Either <prefix> or <suffix> may contain a single %d construct to include\n"
"the counter used while creating the data.\n"
"\n"
"Output:\n"
"	<prefix><data><suffix>\n"
"\n"
"	Note -	No space will be added between items and no new line\n"
"		will be added after the suffix.\n"
"\n";

int
main(int argc, char *argv[])
{
	int	 i;
	int	 j;
	int	 width;
	int	 max;
	char	 fmt[100];
	char	*prefix;
	char	*suffix;
	int	*seed;
	int	*value;

	if (argc < 4) {
		(void) fprintf(stderr, usage);
		return (EXIT_FAILURE);

	} /* if (argc < 3) {...} */

	prefix	= *++argv;
	max	= atoi(*++argv);
	suffix	= *++argv;

	seed	= (int *)malloc(max * sizeof (int));
	if (seed == (int *)NULL) {
		return (EXIT_FAILURE);

	} /* if (seed == (int *)NULL) {...} */

	value	= (int *)malloc(max * sizeof (int));
	if (value == (int *)NULL) {
		return (EXIT_FAILURE);

	} /* if (value == (int *)NULL) {...} */

	for (i = 0; i < max; ++i) {
		seed[i] = i;

	} /* for (i = 0; i < max; ++i) {...} */

	(void) srandom(time((time_t *)NULL));
	for (i = max - 1; i >= 0; --i) {
		j = random() % (i + 1);
		value[i] = seed[j];
		if (j < max - 1) {
			(void) memmove(&seed[j],
			    &seed[j + 1],
			    sizeof (int) * (max - j));

		} /* if (j < max - 1) {...} */

	} /* for (i = max; i > 0 ; --i) {...} */

	for (width = 0, i = max - 1; i; i /= 10) {
		++width;

	} /* for (width = 0, i = max; i; i /=10) {...} */

	(void) snprintf(fmt, sizeof (fmt), "%s%%%d.%dd%s ",
	    prefix,
	    width,
	    width,
	    suffix);

	for (i = 0; i < max; ++i) {
		(void) printf(fmt, value[i], value[i], value[i]);

	} /* for (i = 0; i < max; ++i) {...} */

	return (EXIT_SUCCESS);

} /* int main(int argc, char *argv[]) {...} */
