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

#include <errno.h>
#include <netdb.h>
#include <stddef.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <strings.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>

/*LINTLIBRARY*/

#include <stf.h>
#include <mstf.h>

static FILE *mstf_find_server(void);
static void get_addr_from_string(char *s, char *p,
	struct sockaddr_storage *addr, int *len);
static void mstf_error(char *fcn_name, char *err_string, ...);

static struct sockaddr_storage *mstf_serv_addr = NULL;
static int mstf_serv_addr_len = 0;

/*
 * If multiple test parts are present, wait until all test processes
 * have reached the syncronization point labelled.  If differently
 * labelled sync points are reached by two or more processes, the test
 * has lost synchronization and is terminated.
 *
 * Each call to mstf_sync opens a socket to the sync server, sends the
 * command "sync <label>" over the socket, and waits for a reply.  The
 * reply will be either "go" or "failed".
 *
 * If MSTF_SYNC_SERV is not set in the environment, synchronization fails.
 */
int
mstf_sync(const char *label)
{
	FILE *serv_file;
	char result[MSTF_BUFLEN];

	serv_file = mstf_find_server();

	if (serv_file == NULL) {
		mstf_error("mstf_sync", "failed to connect to sync server");
		return (STF_UNRESOLVED);
	}

	errno = 0;
	(void) fprintf(serv_file, "sync %s\n", label);
	(void) fflush(serv_file);

	if (errno != 0) {
		(void) fclose(serv_file);
		mstf_error("mstf_sync", "failed to write to sync server");
		return (STF_UNRESOLVED);
	}

	do {
		(void) fgets(result, MSTF_BUFLEN, serv_file);
	} while (errno == EINTR);

	if (errno != 0) {
		mstf_error("mstf_sync", "failed to read from sync server");
		return (STF_UNRESOLVED);
	}

	(void) fclose(serv_file);
	if (strncmp(result, "go", 2) == 0) {
		return (STF_PASS);
	}
	if (strncmp(result, "failed", 6) == 0) {
		mstf_error("mstf_sync", "failed at label: %s", label);
	} else {
		mstf_error("mstf_sync", "bad reply [%s] to sync", result);
	}
	return (STF_UNRESOLVED);
}

/*
 * Set a variable in the sync server.
 */
int
mstf_setvar(const char *var_name, const char *value)
{
	FILE *serv_file;

	serv_file = mstf_find_server();

	if (serv_file == NULL) {
		mstf_error("mstf_setvar", "failed to connect to sync server");
		return (STF_UNRESOLVED);
	}

	errno = 0;
	(void) fprintf(serv_file, "setv %s=%s\n", var_name, value);

	if (errno != 0) {
		(void) fclose(serv_file);
		mstf_error("mstf_setvar", "failed to write to sync server");
		return (STF_UNRESOLVED);
	}

	(void) fclose(serv_file);
	return (STF_PASS);
}

/*
 * Get a variable from the sync server.  Any errors connecting will result
 * in exit() being called with return code STF_UNRESOLVED.  The caller supplies
 * a buffer for the value to be returned.  If the value is too large to fit,
 * it is truncated.
 */
int
mstf_getvar(const char *var_name, char *result, int result_len)
{
	FILE *serv_file;

	serv_file = mstf_find_server();

	if (serv_file == NULL) {
		mstf_error("mstf_getvar", "failed to connect to sync server");
		return (STF_UNRESOLVED);
	}

	errno = 0;
	(void) fprintf(serv_file, "getv %s\n", var_name);
	(void) fflush(serv_file);

	if (errno != 0) {
		(void) fclose(serv_file);
		mstf_error("mstf_getvar", "failed to write to sync server");
		return (STF_UNRESOLVED);
	}

	do {
		(void) fgets(result, result_len, serv_file);
	} while (errno == EINTR);

	/* Trim off the \r\n */
	result[strlen(result) - 2] = '\0';

	if (errno != 0) {
		(void) fclose(serv_file);
		mstf_error("mstf_getvar", "failed to read from sync server");
		return (STF_UNRESOLVED);
	}

	(void) fclose(serv_file);
	return (STF_PASS);
}

/*
 * Connect to the synchronization server if possible.  Returns a stream if the
 * the connect was successful, or NULL if and error is encounterd.
 */
FILE *
mstf_find_server(void)
{
	int fd;
	FILE *serv_file;

	if (mstf_serv_addr == NULL) {
		char *addr_string;
		char *port_string;

		/*
		 * This is the first call to mstf_sync.  Lookup and cache
		 * the address of the sync server.
		 */
		addr_string = getenv("MSTF_SYNC_SERV");
		port_string = getenv("MSTF_SYNC_PORT");

		if (addr_string == NULL) {
			(void) fprintf(stderr, "mstf_find_server: "
			    "MSTF_SYNC_SERV must be set the environment\n");
			return (NULL);
		}
		if (port_string == NULL) {
			port_string = MSTF_SYNC_PORT;
		}

		mstf_serv_addr = malloc(sizeof (struct sockaddr_storage));
		if (mstf_serv_addr == NULL) {
			(void) fprintf(stderr, "malloc: no space!\n");
			return (NULL);
		}
		get_addr_from_string(addr_string, port_string, mstf_serv_addr,
		    &mstf_serv_addr_len);
	}

	fd = socket(mstf_serv_addr->ss_family, SOCK_STREAM, IPPROTO_TCP);

	if (fd < 0) {
		(void) close(fd);
		perror("mstf_find_server: socket()");
		return (NULL);
	}

	if (connect(fd, (struct sockaddr *)mstf_serv_addr,
		mstf_serv_addr_len) == -1) {
		(void) close(fd);
		perror("mstf_find_server: failed to connect to sync server");
		return (NULL);
	}

	serv_file = fdopen(fd, "r+");

	if (serv_file == NULL) {
		(void) close(fd);
		perror("mstf_find_server: fdopen()");
	}

	return (serv_file);
}

void
get_addr_from_string(char *s, char *p, struct sockaddr_storage *addr, int *len)
{
	struct addrinfo *ainfo;
	struct addrinfo hints;
	int rval;

	(void) memset(&hints, 0, sizeof (hints));
	hints.ai_family = PF_INET;
	hints.ai_socktype = SOCK_STREAM;

	if ((rval = getaddrinfo(s, p, &hints, &ainfo)) != 0) {
		(void) fprintf(stderr,
			"get_addr_from_string: getaddrinfo: %s\n",
			gai_strerror(rval));
		exit(STF_UNRESOLVED);
	}
	*len = ainfo->ai_addrlen;
	(void) memcpy(addr, ainfo->ai_addr, ainfo->ai_addrlen);
	freeaddrinfo(ainfo);
}

/*PRINTFLIKE2*/
void
mstf_error(char *fcn_name, char *err_string, ...)
{
	va_list args;
	char *env_string;

	va_start(args, err_string);
	(void) fprintf(stderr, "Error: %s:", fcn_name);
	(void) vfprintf(stderr, err_string, args);
	(void) fprintf(stderr, "\n");
	va_end(args);

	env_string = getenv("MSTF_EXIT_ON_ERROR");

	if (env_string != NULL && strncmp(env_string, "1", 2) == 0) {
		exit(STF_UNRESOLVED);
	}
}
