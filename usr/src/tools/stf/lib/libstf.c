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
 */

#include <sys/utsname.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <pwd.h>
#include <stf_impl.h>
#include <stf.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>

/*LINTLIBRARY*/

/*
 *	Beginning of journaling, print start and uname info, called from
 *	jnl_context
 */

static void
pid_error()
{
	static char *msg_pid_error =
	    "STF implementation does not handle getpid() > INT_MAX ";
	int jnl_fd = stf_jnl_open();

	(void) write(jnl_fd, msg_pid_error, strlen(msg_pid_error));
	(void) fsync(jnl_fd);
	exit(1);
}

void
stf_jnl_start()
{
	pid_t pid = getpid();

	if (pid <= INT_MAX) {
		stf_jnl_start_pid((int)pid);
	} else {
		pid_error();
		exit(1);
	}
}

void
stf_jnl_start_pid(int pid)
{
	/* variables for var file */
	char *vfile;
	char vf_string[40];
	static char var_envname[40];
	int var_fd;
	pid_t vpid;
	static struct jvars vf_init;
	struct jvars *vfptr;
	mode_t old_umask;

	/* journal variables */
	struct utsname unames;
	struct passwd *pw;

	char buffer[MAXCHAR + 2];
	char *username;
	char stdtag[] = "stderr| ";

	uid_t userid;
	int jnl_fd;

	/* open journal file */
	jnl_fd = stf_jnl_open();

	if ((vfile = getenv(VARFILE)) == NULL) {
		/* set up the VARFILE env variable for the variable file */
		vpid = getpid();
		(void) snprintf(vf_string, sizeof (vf_string), "%s%ld",
		    VARFNAME, vpid);
		(void) snprintf(var_envname, sizeof (var_envname), "VARFILE=%s",
		    vf_string);
		(void) putenv(var_envname);
		vfile = vf_string;
	}

	/* open and initialize the variable file and it's variables */
	old_umask = umask(0);
	if ((var_fd = open(vfile, (O_CREAT | O_RDWR), 0666)) == -1) {
		perror("jnl_start: vfile_mmap : open");
		(void) snprintf(buffer, sizeof (buffer),
		    "%sjnl_start: vfile_mmap error\n", stdtag);
		(void) write(jnl_fd, buffer, strlen(buffer));
		exit(1);
	}
	(void) umask(old_umask);

	if ((mutex_init(&vf_init.jvar_mlock, USYNC_PROCESS, 0)) != 0) {
		perror("jnl_start: mutex_init ");
		(void) snprintf(buffer, sizeof (buffer),
		    "%sjnl_start: mutex_init error\n", stdtag);
		(void) write(jnl_fd, buffer, strlen(buffer));
		exit(1);
	}

	vf_init.jasrt[0] = '?';
	vf_init.jsubid[0] = '\0';
	vf_init.jargid[0] = '\0';
	vf_init.jseq = 0;
	vf_init.jblk = 0;
	vf_init.jact = 0;
	vf_init.jsubcnt = 0;

	if (write(var_fd, &vf_init, sizeof (struct jvars)) == -1) {
		perror("jnl_start: write ");
		(void) snprintf(buffer, sizeof (buffer),
		    "jnl_start: write error\n");
		(void) write(jnl_fd, buffer, strlen(buffer));
		exit(1);
	}

	vfptr = &vf_init;

	/* mmap the variable file */
	vfptr = (struct jvars *)mmap((caddr_t)0,
	    sizeof (struct jvars),
	    (PROT_READ | PROT_WRITE),
	    MAP_SHARED,
	    var_fd,
	    0);
	if (vfptr == (void *)-1) {
		perror("jnl_start: vfile_mmap : mmap");
		(void) snprintf(buffer, sizeof (buffer),
		    "%sjnl_start: VARFILE mmap error\n", stdtag);
		(void) write(jnl_fd, buffer, strlen(buffer));
		exit(1);
	}
	(void) close(var_fd);

	if (uname(&unames) < 0) {
		(void) snprintf(buffer, sizeof (buffer),
		    "%sjnl_start: uname error\n", stdtag);
		(void) write(jnl_fd, buffer, strlen(buffer));
		exit(1);
	}

	userid = getuid();
	username = (char *)getlogin();

	if (username == (char *)NULL) {
		pw = (struct passwd *)getpwuid(userid);
		if (pw == NULL || pw->pw_name == NULL)
			username = "unknown";
		else
			username = pw->pw_name;
	}

	/* jnl start string (2 lines) */
	(void) snprintf(buffer, sizeof (buffer),
	    "%s| %s %s (%ld) | tpi %1.1f | %s %d |\n",
	    JNL_START,
	    get_dt(),
	    username,
	    (unsigned long)userid,
	    LIBVERS,
	    get_time(),
	    vfptr->jact);

	(void) write(jnl_fd, buffer, strlen(buffer));

	(void) snprintf(buffer, sizeof (buffer), "%s| %d %s %s %s %s %s |\n",
	    JNL_START, pid, unames.sysname,
	    unames.release, unames.version, unames.machine,
	    unames.nodename);
	(void) write(jnl_fd, buffer, strlen(buffer));
}

/* print the environment variables set */
void
stf_jnl_env()
{
	char buffer[MAXCHAR + 2];
	char *buf_ptr;
	char *env_string;
	int jnl_fd;

	jnl_fd = stf_jnl_open();

	/* Getting STF environment variables  and printing them */
	if ((env_string = getenv("STC_NAME")) != NULL) {
		/* get the workspace name  */
		buf_ptr = &buffer[0];
		(void) snprintf(buf_ptr, sizeof (buffer),
		    "%s| STC_NAME = %s |\n", JNL_ENV,
		    env_string);

		print_entry(buffer, jnl_fd);
	}
	if ((env_string = getenv("STC_VERSION")) != NULL) {
		buf_ptr = &buffer[0];
		(void) snprintf(buf_ptr, sizeof (buffer),
		    "%s| STC_VERSION = %s |\n", JNL_ENV, env_string);
		print_entry(buffer, jnl_fd);
	}
	if ((env_string = getenv("STC_OS_VERSION")) != NULL) {
		buf_ptr = &buffer[0];
		(void) snprintf(buf_ptr, sizeof (buffer),
		    "%s| STC_OS_VERSION = %s |\n", JNL_ENV, env_string);
		print_entry(buffer, jnl_fd);
	}
	if ((env_string = getenv("STF_EXECUTE_MODE")) != NULL) {
		buf_ptr = &buffer[0];
		(void) snprintf(buf_ptr, sizeof (buffer),
		    "%s| STF_EXECUTE_MODE = %s |\n", JNL_ENV, env_string);
		print_entry(buffer, jnl_fd);
	}


	if ((env_string = (char *)getcwd(NULL, MAXCHAR)) != NULL) {
		/* get the current working directory */
		buf_ptr = &buffer[0];
		(void) snprintf(buf_ptr, sizeof (buffer),
		    "%s| cwd = %s |\n", JNL_ENV, env_string);
		print_entry(buffer, jnl_fd);
		free(env_string);
	}

	(void) stf_jnl_close(jnl_fd);
}

/* The end of this run */
void
stf_jnl_end()
{
	pid_t pid = getpid();

	if (pid <= INT_MAX) {
		stf_jnl_end_pid((int)pid);
	} else {
		pid_error();
		exit(1);
	}
}

void
stf_jnl_end_pid(int pid)
{
	int jnl_fd;

	char buffer[MAXCHAR + 2];
	char *vfile;

	jnl_fd = stf_jnl_open();
	(void) snprintf(buffer, sizeof (buffer),
	    "%s| %d %s |\n", JNL_END, pid, get_time());
	(void) write(jnl_fd, buffer, strlen(buffer));
	/* remove the varfile */
	if ((vfile = getenv(VARFILE)) != NULL) {
		if (unlink(vfile) != 0) {
			perror("vfile unlink:");
		}
	}
	(void) stf_jnl_close(jnl_fd);
}

void
stf_jnl_msg_pid(int pid, char *msg)
{
	int jnl_fd;

	char buffer[MAXCHAR + 2];
	char *buf_ptr;

	jnl_fd = stf_jnl_open();

	if (*msg == '\0') {
		msg = "?";
	}
	buf_ptr = &buffer[0];
	(void) snprintf(buf_ptr, sizeof (buffer),
	    "%s| %d | %s\n", JNL_MSG, pid, msg);
	print_entry(buffer, jnl_fd);

	(void) stf_jnl_close(jnl_fd);
}

void
stf_jnl_msg(char *msg)
{
	pid_t pid = getpid();

	if (pid <= INT_MAX) {
		stf_jnl_msg_pid((int)pid, msg);
	} else {
		pid_error();
		exit(1);
	}
}


/* Start of Journal Assertion, called from timeout only */
void
stf_jnl_testcase_start_pid(int pid, char **jnl_asrt_line)
{
	/* variables for var file */
	struct jvars *vfptr;
	short activity;

	char buffer[MAXCHAR + 2];
	char *buf_ptr;
	char jnl_asrt_name[MAXCHAR];
	char *name_ptr;
	int jnl_fd;

	jnl_fd = stf_jnl_open();

	jnl_asrt_name[0] = '\0';

	/* separate out the the assertion name, without argument list */
	(void) strcpy(jnl_asrt_name, *jnl_asrt_line);
	for (name_ptr = jnl_asrt_name; *name_ptr != ' '; name_ptr++) {
		;
	}
	*name_ptr = '\0';

	/* get the var file ptr */
	if ((vfptr = vfile_mmap()) == (struct jvars *)-1) {
		activity = -1;
	} else {
		activity = vfptr->jact;

		/* lock the var file and increment the sequence count */
		if (mutex_lock(&(vfptr->jvar_mlock)) != 0) {
			perror("stf_jnl_testcase_start: mutex_lock ");
			exit(1);
		}

		(void) strcpy(vfptr->jasrt, jnl_asrt_name);
		++vfptr->jseq;

		/* unlock the var file */
		if (mutex_unlock(&(vfptr->jvar_mlock)) != 0) {
			perror("stf_jnl_testcase_start: mutex_unlock ");
			exit(1);
		}
	}

	/* print the journal entry */
	buf_ptr = &buffer[0];
	(void) snprintf(buf_ptr, sizeof (buffer), "%s| %d %s | %s %d |\n",
	    JNL_TESTCASE_START, pid, *jnl_asrt_line, get_time(), activity);
	print_entry(buffer, jnl_fd);

	(void) stf_jnl_close(jnl_fd);
}

void
stf_jnl_testcase_start(char **jnl_asrt_line)
{
	pid_t pid = getpid();

	if (pid <= INT_MAX) {
		stf_jnl_testcase_start_pid((int)pid, jnl_asrt_line);
	} else {
		pid_error();
		exit(1);
	}
}

void
stf_jnl_testcase_end(char *jnl_asrt_name, int child_pid, int status)
{
	/* variable for var file */
	struct jvars *vfptr;
	int activity, exitstatus;

	char buffer[MAXCHAR + 2];
	char *buf_ptr, *charptr;
	int jnl_fd;

	jnl_fd = stf_jnl_open();
	if ((vfptr = vfile_mmap()) == (struct jvars *)-1) {
		activity = -1;
	} else {
		activity = vfptr->jact;
		/* lock var file and increment sequence count */
		if ((mutex_lock(&(vfptr->jvar_mlock))) != 0) {
			perror("stf_jnl_testcase_end: mutex_lock ");
			exit(1);
		}

		++vfptr->jseq;

		if ((mutex_unlock(&(vfptr->jvar_mlock))) != 0) {
			perror("stf_jnl_testcase_end: mutex_unlock ");
			exit(1);
		}
	}

	buf_ptr = &buffer[0];

	/* parse the status for signal/status and exit code. */
	charptr = get_status_name((WEXITSTATUS(status)));
	exitstatus = WEXITSTATUS(status);

	if (WIFSIGNALED(status) == 0) {	 /* no signal to print */

		/* if not OTHER don't print exit code */
		if (exitstatus < STF_OTHER) {
			(void) snprintf(buf_ptr, sizeof (buffer),
			    "%s| %d %s | %s | %s %d |\n",
			    JNL_TESTCASE_END, child_pid, jnl_asrt_name,
			    charptr, get_time(), activity);
		} else {	/* print the exit code */
			(void) snprintf(buf_ptr, sizeof (buffer),
			    "%s| %d %s | %s_%d | %s %d |\n",
			    JNL_TESTCASE_END, child_pid, jnl_asrt_name,
			    charptr, exitstatus, get_time(), activity);
		}
	} else {	/* There is a signal number to print.		 */
			/* New and improved! Now if there is a signal to */
			/* print the result "NORESULT" instead of the	 */
			/* usual unix default of 0 (PASS).		 */

		/* Leave result name the same */
		if (exitstatus == STF_TIMED_OUT) {
			(void) snprintf(buf_ptr, sizeof (buffer),
			    "%s| %d %s | %s %d | %s %d |\n",
			    JNL_TESTCASE_END, child_pid, jnl_asrt_name,
			    charptr, WTERMSIG(status), get_time(),
			    activity);
		} else if (exitstatus < STF_OTHER) {
			/* If not OTHER don't print exit code */
			/* Also default the result code to NORESULT w/signal */
			(void) snprintf(buf_ptr, sizeof (buffer),
			    "%s| %d %s | %s %d | %s %d |\n",
			    JNL_TESTCASE_END,
			    child_pid,
			    jnl_asrt_name,
			    result_tbl[NORESULT_INDEX],
			    WTERMSIG(status),
			    get_time(),

			    activity);
		} else { /* This should be OTHER & signal number */
			(void) snprintf(buf_ptr, sizeof (buffer),
			    "%s| %d %s | %s_%d %d | %s %d |\n",
			    JNL_TESTCASE_END, child_pid, jnl_asrt_name,
			    charptr, exitstatus, WTERMSIG(status),
			    get_time(), activity);
		}
	}
	print_entry(buffer, jnl_fd);
	(void) stf_jnl_close(jnl_fd);
	/* Write the result to stdout */
	(void) printf("%s\n", charptr);
	(void) fflush(stdout);
}

void
stf_jnl_assert_start_pid(int pid, char *subid)
{
	struct jvars *vfptr;
	int jnl_fd;

	char buffer[MAXCHAR + 2];
	char *buf_ptr, *sub_id, *asrt, *argid,	nullid[1];
	short activity;

	jnl_fd = stf_jnl_open();

	nullid[0] = '\0';
	/* get varfile ptr if no ptr then default to 0 values */
	if ((vfptr = vfile_mmap()) == (struct jvars *)-1) {
		activity = -1;
		sub_id = subid;
		argid = nullid;
		asrt = nullid;
	} else {
		if (mutex_lock(&(vfptr->jvar_mlock)) != 0) {
			perror("stf_jnl_assert_start: mutex_lock ");
			exit(1);
		}

		activity = vfptr->jact;
		sub_id = subid;

		(void) strcpy(vfptr->jsubid, subid);
		asrt = &vfptr->jasrt[0];
		argid = &vfptr->jargid[0];

		vfptr->jblk = 0;
		vfptr->jseq = 0;

		if (mutex_unlock(&(vfptr->jvar_mlock)) != 0) {
			perror("stf_jnl_assert_start: mutex_unlock ");
			exit(1);
		}
	}

	/* print journal entry */
	buf_ptr = &buffer[0];
	(void) snprintf(buf_ptr, sizeof (buffer),
	    "%s| %d %s%s | %s %d |\n", JNL_ASSERT_START,
	    pid, asrt, build_id(sub_id, argid), get_time(), activity);
	print_entry(buffer, jnl_fd);

	(void) stf_jnl_close(jnl_fd);

}

void
stf_jnl_assert_start(char *subid)
{
	pid_t pid = getpid();

	if (pid <= INT_MAX) {
		stf_jnl_assert_start_pid((int)pid, subid);
	} else {
		pid_error();
		exit(1);
	}
}

void
stf_jnl_assert_end(int result)
{
	pid_t pid = getpid();

	if (pid <= INT_MAX) {
		stf_jnl_assert_end_pid((int)pid, result);
	} else {
		pid_error();
		exit(1);
	}
}

void
stf_jnl_assert_end_pid(int pid, int result)
{
	struct jvars *vfptr;
	char buffer[MAXCHAR + 2];
	char *buf_ptr, *sub_id, *asrt, *argid, nullid[1];
	short activity;
	int jnl_fd;

	jnl_fd = stf_jnl_open();

	nullid[0] = '\0';
	/* get the info from the var file */
	if ((vfptr = vfile_mmap()) == (struct jvars *)-1) {
		activity = -1;
		sub_id = nullid;
		asrt = nullid;
		argid = nullid;
	} else {
		activity = vfptr->jact;
		asrt = &vfptr->jasrt[0];
		sub_id = &vfptr->jsubid[0];
		argid = &vfptr->jargid[0];
	}

	/* translate result to resultstring */

	/* print journal entry */
	buf_ptr = &buffer[0];
	(void) snprintf(buf_ptr, sizeof (buffer),
	    "%s| %d %s%s | %s | %s %d |\n", JNL_ASSERT_END,
	    pid, asrt, build_id(sub_id, argid), get_status_name(result),
	    get_time(), activity);
	print_entry(buffer, jnl_fd);

	(void) stf_jnl_close(jnl_fd);
}

void
stf_jnl_totals(char *id_name, int *result_cts)
{
	pid_t pid = getpid();

	if (pid <= INT_MAX) {
		stf_jnl_totals_pid((int)pid, id_name, result_cts);
	} else {
		pid_error();
		exit(1);
	}
}

void
stf_jnl_totals_pid(int pid, char *id_name, int *result_cts)
{
	struct jvars *vfptr;

	int i;
	char all_results[MAXCHAR],  buffer[MAXCHAR + 2], nullid[1];
	char one_result[20];
	char *buf_ptr, *results_ptr, *asrt;
	int jnl_fd;

	jnl_fd = stf_jnl_open();

	nullid[0] = '\0';

	/* Get the assertion name from the varfile */
	if ((vfptr = vfile_mmap()) == (struct jvars *)-1) {
		asrt = nullid;
	} else {
		asrt = &vfptr->jasrt[0];
	}

	all_results[0] = '\0';
	results_ptr = all_results;

	for (i = 0; i < STF_MAX_RESULTS; i++) {
		if (result_cts[i] != 0) {
			(void) snprintf(one_result, sizeof (one_result),
			    " %s:%d", result_tbl[i],
			    result_cts[i]);
			(void) strcat(results_ptr, one_result);
		}
	}

	buf_ptr = &buffer[0];
	(void) snprintf(buf_ptr, sizeof (buffer),
	    "%s| %d %s%s |%s\n", JNL_TOTALS, pid,
	    asrt, build_id(id_name, (char *)NULL), results_ptr);
	print_entry(buffer, jnl_fd);

	(void) stf_jnl_close(jnl_fd);
}

void
harness_error(char *errorbuf)
{
	int jfd;
	char printbuf[MAXCHAR];

	jfd = stf_jnl_open();

	(void) snprintf(printbuf, sizeof (printbuf),
	    "XXX| STF harness error: %s\n", errorbuf);
	(void) write(jfd, printbuf, strlen(printbuf));

	(void) stf_jnl_close(jfd);
}

/* get date */
static char *
get_dt()
{
	time_t t;
	struct tm *tp;
	static char dt_str[20];

	(void) time(&t);
	if ((tp = localtime(&t)) == NULL) {
		(void) fprintf(stderr, "error in localtime\n");
		exit(1);
	}
	(void) snprintf(dt_str, sizeof (dt_str),
	    "%04d%02d%02d", tp->tm_year + 1900, tp->tm_mon + 1,
	    tp->tm_mday);
	return (dt_str);
}

/* build the printed string for assertion:subid(argid) */
static char *
build_id(char *sub_id, char *arg_id)
{
	static char id_string[MAXCHAR];

	id_string[0] = '\0';

	if (*sub_id != NULL) {
		(void) strcat(id_string, ":");
		(void) strcat(id_string, sub_id);

	}
	if (arg_id == NULL) {	/* null pointer? */
		return (id_string);
	}

	if (*arg_id != NULL) {
		(void) strcat(id_string, "(");
		(void) strcat(id_string, arg_id);
		(void) strcat(id_string, ")");
	}
	return (id_string);
}

static char *
get_time()
{
	time_t t;
	struct tm *tp;
	static char time_str[32];

	(void) time(&t);
	if ((tp = localtime(&t)) == NULL) {
		(void) fprintf(stderr, "error in localtime\n");
		exit(1);
	}
	(void) snprintf(time_str, sizeof (time_str),
	    "%02d:%02d:%02d %llu", tp->tm_hour, tp->tm_min,
	    tp->tm_sec, gethrtime());
	return (time_str);
}

/* print the buffer */
void
print_entry(char *jnl_ptr, int fd)
{
	(void) write(fd, jnl_ptr, strlen(jnl_ptr));
}

/* map the result code to result name in the name table, jnl.h	*/
/* if result code is out of range the default is OTHER		*/
static char *
get_status_name(int exit_no)
{
	return (exit_no < 0 || exit_no > (STF_MAX_RESULTS - 1))
	    ? result_tbl[OTHER_INDEX] : result_tbl[exit_no];
}

int
stf_jnl_open()
{
	char *jnl_file;
	int jnl_fd;

	/*	get journal name from environment and open it	*/
	jnl_file = (char *)getenv(JNLNAME);
	if (jnl_file == NULL) { /* no env var for jnl file set */
		/* default to stdout */
		jnl_fd = 1;
		/* fdopen(jnl_fd, "w+"); */
	} else {
		if ((jnl_fd = open(jnl_file, (O_CREAT | O_WRONLY | O_APPEND),
		    0666)) == -1) {
			perror("stf_jnl_open: jnlfile open");
			exit(1);
		}
	}
	return (jnl_fd);
}

int
stf_jnl_close(int fd)
{
	if (fd == 1)
		return (0);
	else {
		return (close(fd));
	}
}

struct jvars *
vfile_mmap()
{
	static struct jvars *jv = 0;
	char *vfile;
	int var_fd;
	mode_t old_umask;

	if (jv) { /* already mmapped */
		return (jv);
	}

	if ((vfile = getenv(VARFILE)) == NULL) {
		/*
		 * VARFILE environment variable not set,
		 * values will default to -1
		 */
		return ((struct jvars *)-1);
	}

	old_umask = umask(0);
	if ((var_fd = open(vfile, O_RDWR)) == -1) {
		perror("vfile_mmap : open");
		(void) umask(old_umask);
		return ((struct jvars *)-1);
	}
	(void) umask(old_umask);

	jv = (struct jvars *)mmap((caddr_t)0,
	    sizeof (struct jvars),
	    (PROT_READ | PROT_WRITE),
	    MAP_SHARED,
	    var_fd,
	    0);

	if (jv == (void *)-1) {
		perror("vfile_mmap : mmap");
		return ((struct jvars *)-1);
	}
	(void) close(var_fd);
	return (jv);
}

static void
_case_init_();

#pragma init(_case_init_)

static void
_case_init_()
{
	setbuf(stdout, NULL);
}
