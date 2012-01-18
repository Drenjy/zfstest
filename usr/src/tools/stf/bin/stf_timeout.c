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

/*
 * stf_timeout - limit the execution time of a command and report start/stop
 *
 * 	Usage: timeout [options] limit command
 *
 *	options:
 *	-n name	- name of testcase to use in journal
 *	-q	- quiet mode, some journaling suppressed
 *	-s	- suspend hung process instead of killing it
 *
 *	limit	- integer time limit in seconds or of the form 3h23m45s
 *	command	- command line
 */

#include <stf_impl.h>
#include <ctype.h>
#include <signal.h>
#include <stropts.h>
#include <poll.h>
#include <sys/resource.h>
#include <unistd.h>
#include <limits.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>

#define	NFDS	2

static int timed_out;
static int test_pid = -1;
static int process_fd;

static char process_file[32] = "/proc/";

enum units {hours, minutes, seconds, none};

/* prototypes */
static void wake_up();
static void usage();
static int poll_process(hrtime_t timeout_end, int suspendflag);
static void parse_timeout(char *, time_t *duration);
static time_t parse_value(char **stringpp, enum units *value_units);

static void
clean_kill(int test_pid)
{
	int i, child_status;
	if (test_pid > 0) {
		(void) kill(-test_pid, SIGHUP);
		for (i = 0; i < 10; i++) {
			if (waitpid(test_pid, &child_status, WNOHANG)
			    == test_pid) {
				break;
			}
			(void) sleep(1);
		}
		(void) kill(-test_pid, SIGKILL);
		(void) sleep(3);
	}

}

/*ARGSUSED*/

static void
goodbye(int signum)
{
	if (test_pid > 0) clean_kill(test_pid);
	exit(1);
}

int
main(int argc, char *argv[])
{
	extern int optind;
	char **prgargs, *options = "sqn:";
	char *timeoutarg;
	int quiet = 0;		/* suppress (some) printing of jnl lines */
	int suspend = 0;	/* set so that a hung process is not killed */
	int child_pid, child_status, c;
	int tmp_status;
	pid_t mypid;
	time_t duration;
	hrtime_t end_time;
	char *name = NULL;
	char *tempname;
	int nflag = 0;		/* use name for the testcase in jnl */
	timed_out = 0;

	if (argc < 2) {
		usage();
		exit(1);
	}

	suspend = (getenv("STF_SUSPEND") != NULL);

	while ((c = getopt(argc, argv, options)) != EOF) {
		switch (c) {

			case 's':
				suspend = 1;
				break;
			case 'q':
				quiet = 1;
				break;
			case 'n':
				nflag = 1;
				name = optarg;
				break;
		}
	}
	/* get timeout value */
	timeoutarg = argv[optind];
	parse_timeout(timeoutarg, &duration);
	++optind;

	/* program name and args pointer */
	if (optind < argc) {
		prgargs = &(argv[optind]);
		tempname = prgargs[0];
	} else {
		usage();
		(void) fprintf(stderr, "	missing command name\n");
		exit(1);
	}


	/* for timeout value */
	end_time = gethrtime() + (duration * (hrtime_t)NANOSEC);
	(void) signal(SIGHUP, goodbye);
	(void) signal(SIGINT, goodbye);
	(void) signal(SIGQUIT, goodbye);
	(void) signal(SIGTERM, goodbye);

	if ((test_pid = fork1()) == 0) {	/* this is the child */
		/*
		 * Set the child to be the process group leader.
		 * The session id is left the same.
		 */
		mypid = getpid();
		(void) setpgid(mypid, mypid);
		if (quiet == 0) {
			if (nflag == 1)
				prgargs[0] = name;
			stf_jnl_testcase_start(prgargs);
			if (nflag == 1)
				prgargs[0] = tempname;
		}

		(void) execvp(prgargs[0], &prgargs[0]);
		perror("timeout: exec failed");
		(void) fprintf(stderr, "exec file is: %s\n", prgargs[0]);
		exit(1);
	}
	if (test_pid == -1) {
		perror("Fork failed");
		exit(1);
	}
	(void) sprintf(process_file, "%s%d", process_file, test_pid);
	if ((process_fd = open(process_file, O_RDONLY, 0666)) == -1) {
		perror("timeout: proc file open");
		exit(1);
	}

	(void) poll_process(end_time, suspend);
	child_pid = waitpid(test_pid, &child_status, 0);

	/* A time out defaults to an exit status of 0, */
	/* here we force a time out status, while retaining the sig */
	if (timed_out == 1) {  /* fake a time_out status for time out */
		tmp_status = child_status;
		/* mask in an exit status, make sure it's set to zero first */
		child_status = (tmp_status & 0xffff00ff) |
		    (TIMED_OUT_INDEX << 8);
	}

	if (quiet == 0) {
		if (nflag == 1)
			prgargs[0] = name;
		stf_jnl_testcase_end(name, child_pid, child_status);
		if (nflag == 1)
			prgargs[0] = tempname;
	}
	return (WEXITSTATUS(child_status));
}

/*
 * poll on the pipe and child process to see what to do next
 */
static int
poll_process(hrtime_t timeout_end, int suspendflag)
{
	int pollval;
	int polltimeout;

	pollfd_t pollfds;

	pollfds.fd = process_fd;
	pollfds.events = POLLPRI;

	for (;;) {
		if ((polltimeout = (int)((timeout_end - gethrtime()) /
		    (hrtime_t)NANOSEC)) < 0) {
			pollval = 0;
		} else {
			pollval = poll(&pollfds, 1, polltimeout * 1000);
		}
		switch (pollval) {
			case -1:
				/* error */
				(void) fprintf(stderr,
				    "poll failed, errno=%d (%s)\n", errno,
				    strerror(errno));
				exit(1);
				break;
			case 0:
				/* timeout */

				/*
				 * Check that someone hasn't messed
				 * with the clock
				 */
				if ((timeout_end - gethrtime()) > 0) {
					continue;
				}

				if (suspendflag == 0) {
					wake_up();
				} else {
					(void) fprintf(stderr,
		    "\nprocess %d - timed out, suspend flag set, not killed\n",
					    test_pid);
				}
				return (0);

			default: /* event of interest */
				break;
		}
		switch (pollfds.revents) {
			case POLLPRI:
			/* return for now, may want to check later */
				(void) fprintf(stderr, "pollpri error\n");
				return (0);
			case POLLERR:
			/* error */
				perror("poll error:");
				return (0);
			case POLLHUP:
			/* child finished */
				/* get child pids too */
				(void) kill(-test_pid, SIGKILL);
				return (0);
			case POLLNVAL:
			/* may want to go into more detail later */
				perror("poll fd val:");
				return (0);
			default:
				break;
		}
	}
}

static void
wake_up(void)
{
	timed_out = 1;
	(void) fprintf(stderr, "\nprocess %d - timed out\n", test_pid);
	clean_kill(test_pid);	/* and the grandchild pids too */
}

static void
usage(void)
{
	(void) fprintf(stderr,
	"Usage: timeout [options] limit command.\n");
	(void) fprintf(stderr,
	"\noptions:\n");
	(void) fprintf(stderr,
	"\t-n name\t - name of testcase to use in journal\n");
	(void) fprintf(stderr,
	"\t-q\t- quite mode, some journaling suppressed\n");
	(void) fprintf(stderr,
	"\t-s\t- suspend hung process instead of killing it\n\n");
	(void) fprintf(stderr,
	"\tlimit\t- integer time limit in seconds or of the form 3h23m45s\n");
	(void) fprintf(stderr,
	"\tcommand\t- command line\n");
}

/*
 * parse_timeout(limit_string, duration)
 *	parse the argument limit_string
 *	   <time>: do the command until <time> has passed
 *		<time> is of the form 3h23m45s
 *		if it's just a number the default is for
 *		seconds for backwards compatibility.
 */
static void
parse_timeout(char *limit_string, time_t *duration)
{
	char *value_string = limit_string;
	time_t value;
	enum units value_units;

	*duration = (time_t)-1;

	value = parse_value(&value_string, &value_units);
	*duration = 0;
	if (value_units == hours) {
		*duration = 60 * 60 * value;
		value = parse_value(&value_string, &value_units);
	}
	if (value_units == minutes) {
		*duration += 60 * value;
		value = parse_value(&value_string, &value_units);
	}
	if (value_units == seconds) {
		*duration += value;
		value = parse_value(&value_string, &value_units);
	}
	if (value_units == none) {	/* all processed */
		*duration += value;	/* default to seconds */
		if (*duration == 0) {
			(void) fprintf(stderr,
			    "duration <%s> is 0\n",
			    limit_string);

		}
		return;
	}
	(void) fprintf(stderr, "time limit <%s> is bad\n", limit_string);
}

/*
 * parse_value(stringpp, value_units)
 *	Extract a value from the string, and return it.
 *	Move string pointer.  Set units of the value.
 */
static time_t
parse_value(char **stringpp, enum units *value_units)
{
	time_t value;
	char *new_stringp;

	errno = 0;	/* since we'll be checking it when perhaps no error */

	/* the cast is valid */
	value = (time_t)strtol(*stringpp, &new_stringp, 10);
	if ((value == INT_MAX || value == INT_MIN) && errno == ERANGE) {
		(void) fprintf(stderr, "limit <%s> exceeds maximum allowed"
		    " value %u\n", *stringpp, INT_MAX);
	}
	switch (*new_stringp) {
	case NULL:
		*value_units = none;
		break;
	case 'h':
		*value_units = hours;
		new_stringp++;
		break;
	case 'm':
		*value_units = minutes;
		new_stringp++;
		break;
	case 's':
		*value_units = seconds;
		new_stringp++;
		break;
	default:
		(void) fprintf(stderr, "bad limit value <%s>, unrecognized "
		    "character %c\n", *stringpp, *new_stringp);
	}
	*stringpp = new_stringp;
	return (value);
}
