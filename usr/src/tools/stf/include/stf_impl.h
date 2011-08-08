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
 * Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 *
 */

#ifndef _STF_IMPL_H
#define	_STF_IMPL_H

#pragma ident	"@(#)stf_impl.h	1.9	08/11/21 SMI"

#ifdef __cplusplus
extern "C" {
#endif

#include <stf.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <wait.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <synch.h>

#define	LIBVERS 1.4	/* libtpi version number, same as VERS in Makefile */
#define	MAXCHAR 1024

/* reference codes */
#define	JNL_START		"Start"
#define	JNL_END			"End"
#define	JNL_ENV			"STF_ENV"
#define	JNL_TESTCASE_START	"Test_Case_Start"
#define	JNL_TESTCASE_END	"Test_Case_End"
#define	JNL_ASSERT_START	"Assertion_Start"
#define	JNL_ASSERT_END		"Assertion_End"
#define	JNL_MSG			"Msg"
#define	JNL_TOTALS		"Totals"

/* Journal variable file */
#define	VARFNAME	"/tmp/stf_varfile."

/* Environment Variables */
#define	VARFILE		"VARFILE"	/* variable file, get appended w/pid */
#define	JNLNAME		"STF_JOURNAL"	/* journal file */
#define	SUITE		"SUITE"		/* suite name */
#define	TBIN		"TBIN"		/* test binary dir */
#define	TRES		"TRES"		/* test results dir */
#define	TEXP		"TEXP"		/* test ?? */
#define	DIR		"DIR"		/* test ?? */

/* format of jvarfile */
struct jvars {
	mutex_t jvar_mlock;
	char jasrt[256];
	char jsubid[256];
	char jargid[256];
	unsigned int short jseq;
	unsigned int short jblk;
	unsigned int short jact;
	unsigned int short jsubcnt;
};

void stf_jnl_end();
void stf_jnl_env();
void stf_jnl_msg(char *);
void stf_jnl_start();
void stf_jnl_start_pid(int);
void stf_jnl_end_pid(int);
void stf_jnl_testcase_start_pid(int, char **);
void stf_jnl_testcase_end_pid(int, char *);
void stf_jnl_assert_start_pid(int, char *);
void stf_jnl_assert_end_pid(int, int);
void stf_jnl_totals_pid(int, char *, int *);

static char *get_dt(void);
static char *get_status_name(int);
static char *get_time(void);
static void print_entry(char *, int);
static char *build_id(char *sub_id, char *arg_id);

static struct jvars *
vfile_mmap();

int stf_jnl_open();
int stf_jnl_close();

#ifdef __cplusplus
}
#endif

#endif /* _STF_IMPL_H */
