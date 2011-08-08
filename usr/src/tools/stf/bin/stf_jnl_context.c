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

#pragma ident	"@(#)stf_jnl_context.c	1.12	07/05/07 SMI"

/*
 * stf_jnl_context.c - set up the pipes for capturing output for journal
 *	start-up.
 */

#include <ctype.h>
#include <sys/conf.h>
#include <signal.h>
#include <stropts.h>
#include <poll.h>
#include <sys/resource.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <stdlib.h>

#include <stf_impl.h>

#define	VARFNAME	"/tmp/stf_varfile."

/*
 * polling on	1) child process
 *		2) stdout
 *		3) stderr and jnl output (on same pipe)
 */
#define	NFDS	3

/* prototypes */
static int read_pipe();
static void write_pipe(int pipenum, ssize_t bytes, char buf[]);
static void usage();

static pollfd_t pollfd_proc;
static pollfd_t pollfd_pipe[2];
static int test_pid = -1;

/* stdout and jnl output pipe */
static int pivec1[2];
/* stderr pipe */
static int pipe_err[2];

static int jnl_con_fd, proc_fd;

static char proc_file[32] = "/proc/";

/* stdout storage buffer */
static char outbuf[MAXCHAR+12];
/* pointer to stdout storage buffer */
static char *p_out = outbuf;

static short cr_needed = 0;  /* flag for carriage return */

static void
usage()
{
	(void) fprintf(stderr, "Usage: jnl_context command\n");
}

/*ARGSUSED*/
static void
goodbye(int signum)
{
	if (test_pid > 0) {
		(void) kill(-test_pid, SIGHUP);
		return;
	}

	exit(EXIT_FAILURE);
}

int
main(int argc, char *argv[])
{
	ssize_t lastct;
	char pbuf[MAXCHAR];
	int i;
	pid_t mypid;
	int stat;

	if (argc < 1) {
		usage();
		return (EXIT_FAILURE);
	}

	if (pipe(pivec1) == -1) {
		perror("jnl_context: pipe");
		return (EXIT_FAILURE);
	}
	if (pipe(pipe_err) == -1) {
		perror("jnl_context: pipe");
		return (EXIT_FAILURE);
	}

	/* set ups var file mmap and prints begin messages */
	jnl_con_fd = stf_jnl_open();

	(void) signal(SIGHUP, goodbye);
	(void) signal(SIGINT, goodbye);
	(void) signal(SIGQUIT, goodbye);
	(void) signal(SIGTERM, goodbye);

	/* start journaling */
	if ((test_pid = fork1()) == 0) {	/* this is the child */
		/*
		 * Set the child to be the process group leader.
		 * The session id is left the same.
		 */
		mypid = getpid();
		(void) setpgid(mypid, mypid);

		(void) dup2(pivec1[0], 1);	/* stdout => pivec1[0] */
		(void) dup2(pipe_err[0], 2);	/* stderr => pipe_err[0] */

		closefrom(STDERR_FILENO + 1);

		(void) execvp(argv[1], &argv[1]);
		perror("jnl_context: exec failed");
		return (EXIT_FAILURE);
	}

	if (test_pid == -1) {
		perror("Fork failed");
		(void) fprintf(stderr, "jnl_context: fork failed.\n");
		return (EXIT_FAILURE);
	}
	(void) close(pivec1[0]);
	(void) close(pipe_err[0]);

	(void) sprintf(proc_file, "%s%d", proc_file, test_pid);
	if ((proc_fd = open(proc_file, O_RDONLY, 0666)) == -1) {
		perror("proc file open");
		return (EXIT_FAILURE);
	}

	(void) read_pipe();
	/* Anything left in the pipes ? Final read. */
	for (i = 0; i < 2; i++) {
		while ((lastct = read(pollfd_pipe[i].fd,
				pbuf, sizeof (pbuf))) > 0) {
			write_pipe(i, lastct, pbuf);
		}
	}
	if (p_out != outbuf) {	/* did the stdout buffer get printed? */
		if (cr_needed == 1)
			(void) write(jnl_con_fd, "\n", 1);
		(void) write(jnl_con_fd, &outbuf, strlen(outbuf));
		(void) write(jnl_con_fd, "\n", 1);
		cr_needed = 0;
	}

	if (cr_needed == 1)
		(void) write(jnl_con_fd, "\n", 1);

	/* journal end here, done with journal */
	/* stf_jnl_end_pid(test_pid); */

	while (waitpid(test_pid, &stat, 0) != test_pid);
	if (WIFEXITED(stat))
		stat = WEXITSTATUS(stat);

	(void) kill(-test_pid, SIGKILL);
	return (stat);
}

/*
 * poll on the pipe and child process to see what to do next
 */
static int
read_pipe()
{
	char buf[MAXCHAR];
	int pollval;
	ssize_t count;
	int j;
	short events;	/* temp revents holder */

	/* child process */
	pollfd_proc.fd = proc_fd;
	pollfd_proc.events = POLLPRI;

	/* stdout and jnl pipe */
	pollfd_pipe[0].fd = pivec1[1];
	pollfd_pipe[0].events = POLLIN | POLLRDNORM | POLLRDBAND;

	/* stderr pipe */
	pollfd_pipe[1].fd = pipe_err[1];
	pollfd_pipe[1].events = POLLIN | POLLRDNORM | POLLRDBAND;

	for (;;) {
		if ((pollval = poll(pollfd_pipe, 2, 5)) < 0) {
		/* poll on pipes */
			/* error */
			perror("poll failed\n");
			(void) printf("errno=%d\n", errno);
			return (0);
		}
		if (pollval == 0) { /* pipe timed out */
			if ((pollval = poll(&pollfd_proc, 1, 10)) < 0) {
			/* poll on proc */
				/* error */
				perror("poll failed\n");
				(void) printf("errno=%d\n", errno);
				return (0);
			}
			if (pollval == 0) { /* proc */
				continue;
			}
		}

		for (j = 0; j < 2; j++) { /* check the pipes for data */
			if (!(pollfd_pipe[j].revents)) continue;

			events = pollfd_pipe[j].revents;

			if (events & POLLERR) {
				/* error */
				perror("poll error:");
				return (0);
			}
			if (events & (POLLIN | POLLRDNORM | POLLRDBAND)) {
			    /* Incomming data on pipe to be journalled */
				if ((count = read(pollfd_pipe[j].fd,
						buf, sizeof (buf))) > 0) {
					(void) write_pipe(j, count, buf);
				}
			}
			if (events & POLLHUP) {
				/* child finished */
				/*	kill(-test_pid, SIGKILL);	*/
				return (0);
			}
		}

		/* Check the proc events */

		if (!(pollfd_proc.revents))	continue;

		events = pollfd_proc.revents;

		if (events & POLLERR) {
			/* error */
			perror("poll error:");
			return (0);
		}
		if (events & POLLHUP) {
			/* child finished */
			/*	kill(-test_pid, SIGKILL);	*/
			return (0);
		}
	}
}

/*
 * process the output stream in buffer, adding std tags where needed
 */
static void
write_pipe(int pipenum, ssize_t nbytes, char buf[])
{
	const char stdout_tag[] = "stdout| ";
	const char stderr_tag[] = "stderr| ";
	unsigned int i;
	static unsigned int outcount = 0;
	/* flag for a journal entry */
	static unsigned short jnl_entry = 0;
	/* flag for whether stdout tag was written */
	static unsigned short out_tagged = 0;
	/* flag as to whether stderr tag was written */
	static short err_tagged = 0;
	static char errmsg[MAXCHAR];

/*
 * note: all stdout messages are buffered until a new line is reached
 *	any stderr messages and jnl messages are assumed to be
 *	unbuffered so the characters should be printed as received
 */

for (i = 0; i < nbytes; i++) {

		switch (buf[i]) {
		case '\0':
			if (pipenum == 0) {  /* begin jnl entry */
				jnl_entry = 1;
				if (cr_needed == 1) {
					(void) write(jnl_con_fd, "\n", 1);
					cr_needed = 0;
				}
			} else {  /* stderr, print it now */
				(void) write(jnl_con_fd, &buf[i], 1);
				cr_needed = 1;
			}
			break;

		case '\n':
			cr_needed = 0;
			if (jnl_entry == 1) {  /* eol jnl entry */
				(void) write(jnl_con_fd, &buf[i], 1);
				jnl_entry = 0;

			} else if (pipenum == 1) {	/* eol of stderr */
				if (err_tagged == 0) {	/* print stderr tag */
					(void) write(jnl_con_fd, &stderr_tag,
						sizeof (stderr_tag) - 1);
					err_tagged = 1;
				}
				(void) write(jnl_con_fd, &buf[i], 1);
				err_tagged = 0;

			} else {  /* eol buffered stdout */
				if (out_tagged == 0) {	/* buffered stdout */
					p_out += snprintf(p_out, (MAXCHAR + 12)
						- (p_out - outbuf),
						"%s", stdout_tag);
					out_tagged = 1;
				}
				p_out += snprintf(p_out,
					(MAXCHAR + 12) - (p_out - outbuf),
					"%c", buf[i]);
				(void) write(jnl_con_fd, &outbuf,
					strlen(outbuf));
					/* print the buffer */
				p_out = outbuf; /* reset to beginning */
				outcount = 0;
				out_tagged = 0;
			}
			break;

		default:
			if (jnl_entry == 1) { /* jnl */
				(void) write(jnl_con_fd, &buf[i], 1);
				break;

			} else if (pipenum == 1) { /* stderr */
				if (err_tagged == 0) {
					(void) write(jnl_con_fd, &stderr_tag,
						sizeof (stderr_tag) - 1);
					err_tagged = 1;
				}
				(void) write(jnl_con_fd, &buf[i], 1);
				cr_needed = 1;
				break;

			} else {  /* buffered stdout */
				if (out_tagged == 0) {	/* buffered stdout */
					p_out += snprintf(p_out,
					    (MAXCHAR + 12) - (p_out - outbuf),
					    "%s", stdout_tag);
					out_tagged = 1;
				}
				p_out += snprintf(p_out,
				    (MAXCHAR + 12) - (p_out - outbuf),
				    "%c", buf[i]);
					/* assume it is stdout */
				++outcount;

				/* check size of stdout buffer */
				if (outcount > MAXCHAR - 1) {	/* overflow */
					(void) write(jnl_con_fd,
					    &outbuf,
					    strlen(outbuf));

					(void) snprintf(errmsg, MAXCHAR,
					    "\n%s: Warning: buffer overflow,"
					    " lines limited to %d bytes\n",
					    stderr_tag,
					    MAXCHAR);

					(void) write(jnl_con_fd,
					    &errmsg,
					    strlen(errmsg));

					p_out = outbuf; /* reset to beginning */
					out_tagged = 0;
					outcount = 0;
					cr_needed = 0;
				}
			}
			break;
		}
	}
}
