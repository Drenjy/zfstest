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

/*
 * basic.c
 *
 * Description:
 *	Perform basic functional testing on the hashytable library.
 */

/*
 * Compiler version dependencies.
 *
 * Some of the macros used in this code depend on features only available in
 * version 6.1 and later of the SunPro C compiler.
 */
#define	SUNWPRO_VERSION_POST60	(__SUNPRO_C >= 0x520)

#include <errno.h>
#include <fcntl.h>
#include <limits.h>

#if ! SUNWPRO_VERSION_POST60
#include <stdarg.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <hashtable.h>

static const char usage[] = {
"\n"
" Usage:\n"
"	basic	[-create <numents> <keysize> <options>]\n"
"		[-resize <numents>]\n"
"		[-destroy]\n"
"		[-insert <key> <data>]\n"
"		[-delete <key>]\n"
"		[-file <filename>]\n"
"		[-ignore [<count>]]\n"
"\n"
"	Where;\n"
"		-create <numents> <keysize> <options>\n"
"			creates a hashtable with <numents> entries\n"
"			using keys of <keysize> bytes and <options>\n"
"			hash table options.\n"
"\n"
"		-resize <numents>\n"
"			resizes the table to have <numents> entries.\n"
"\n"
"		-destroy\n"
"			destroys the table.\n"
"\n"
"		-insert <key> <data>\n"
"			inserts <data> using <key>. A copy of <key> and\n"
"			<data> are kept until the table is destroyed.\n"
"\n"
"		-locate <key> <data>\n"
"			locates <data> using <key>. The value of <data> is\n"
"			compared to the data saved when inserted and an\n"
"			error is reported if they do not match.\n"
"\n"
"		-delete\n"
"			deletes <key> from the table. This may fail if\n"
"			<key> has never been inserted.\n"
"\n"
"		-file <filename>\n"
"			specifies the name of a text file from which\n"
"			subsquent commands should be read. This behaves\n"
"			as an insert here command. Once eof has been\n"
"			reached in the file, following commands from the\n"
"			program parameters will be processed.\n"
"\n"
"		-ignore [<count>]"
"			specifies the number of errors to ignore while\n"
"			processing following commands. This command may\n"
"			be peppered within any string of commands.\n"
"\n"
"		-verbose <level>\n"
"			Sets the verbosity to <level>. The higher the\n"
"			number, the more progress message get printed.\n"
"\n"
"	Note:	This program does not use STC journal calls because\n"
"		the extended journal calls make use of the hashtable\n"
"		code itself.\n"
"\n"
" Return value\n"
"	If none of the commands fails, then the program exit status will be\n"
"	zero. If any of the commands fail, then a non-zero value will be\n"
"	returned.\n"
"\n"
};

/*
 * Keywords for valid commands to this program. The enumerated list and the
 * array of words must correspond.
 */
typedef enum keyword_numbers {
	k_min_			= 0,
	k_create		= k_min_,
	k_delete	/*	= 1	*/,
	k_destroy	/*	= 2	*/,
	k_file		/*	= 3	*/,
	k_ignore	/*	= 4	*/,
	k_insert	/*	= 5	*/,
	k_locate	/*	= 6	*/,
	k_resize	/*	= 7	*/,
	k_verbose	/*	= 8	*/,
	k_max_
} keyword_t;

static const char *keywords[] = {
	"-create",
	"-delete",
	"-destroy",
	"-file",
	"-ignore",
	"-insert",
	"-locate",
	"-resize",
	"-verbose",
	(char *)NULL
};

static int verbose = 0;	/* Should I print everyting?	*/

#if ! SUNWPRO_VERSION_POST60

static char	*__file__;	/* Saved file name from macro.		*/
static int	 __line__;	/* Saved line number from macro.	*/

#define	LOCATION_	__file__ = __FILE__; __line__ = __LINE__

#endif

/*
 * void
 * em(char *format_string, ...);
 *
 * Description:
 *	Format an error message and print it on stderr.
 *
 * Parameters:
 *	char *format_string
 *		Input - printf() style format string.
 *
 *	...
 *		Input - sufficient vargs to satisfy the format string.
 *
 * Return value:
 *	None.
 */
#if SUNWPRO_VERSION_POST60

#define	em(...) \
	(void) fprintf(stderr, "(%s, %d) ", __FILE__, __LINE__); \
	(void) fprintf(stderr, __VA_ARGS__)

#else /* ! COMPILER6POST */

#define	em	LOCATION_; em_

void
em_(const char *fmt, ...)
{
	va_list	ap;		/* Variable argument pointer.		*/

	(void) printf("(%s, %d) ", __file__, __line__);
	va_start(ap, fmt);
	(void) vprintf(fmt, ap);
	va_end(ap);

} /* void em_(fmt, ...) {...} */

#endif	/* #if COMPILER6POST ... #else ... */

/*
 * void
 * info(char *format_string, ...)
 *
 * Description:
 *	Print progress information iff verbose != 0.
 *
 * Parameters:
 *	char *format_string
 *		Input - printf() style format string.
 *
 *	...
 *		Input - Sufficient parameters to satisfy format_string.
 *
 * Return value:
 *	None.
 */
#if SUNWPRO_VERSION_POST60

#define	info(level, ...) if (verbose >= level) { \
	(void) printf("(%s, %d) ", __FILE__, __LINE__); \
	(void) printf(__VA_ARGS__); \
	}

#else /* ! COMPILER6POST */

#define	info LOCATION_; info_

void
info_(int level, char *fmt, ...)
{
	va_list	ap;		/* Variable argument pointer.		*/

	if (verbose >= level) {
		(void) printf("(%s, %d) ", __file__, __line__);
		va_start(ap, fmt);
		(void) vprintf(fmt, ap);
		va_end(ap);

	} /* if (verbose >= level) {...} */

} /* void info_ (level, ...) {...} */


#endif	/* #if COMPILER6POST ... #else ... */

/*
 * char *
 * line_next(char *line);
 *
 * Description:
 *	Return a pointer to the next new line character.
 *
 * Parameters:
 *	char *line
 *		Input - A pointer to any character in a given line.
 *
 * Return value:
 *	char *	A pointer to the new line character at the end of the current
 *		line.
 */
static char *
eol(char *line)
{
	while (*line != '\0' && *line != '\n')
		++line;

	return (line);

} /* char *line_next(char *line) {...} */

/*
 * static int
 * string_count(char *strings[]);
 *
 * Description:
 *	Count the number of strings in the table passed.
 *
 * Parameters:
 *	char *strings[]
 *		Input - Poihter to an array of strings to be counted.
 *
 * Return value:
 *	int	Count of the number of strings in the table.
 */
static int
string_count(const char *strings[])
{
	/*
	 * Locals...
	 */
	int	count;

	/*
	 * Just look for the null pointer.
	 */
	for (count = 0; *strings != (char *)NULL; ++strings) {
		++count;

	} /* for (count = 0; *string != (char *)NULL; ++string) {...} */

	/*
	 * All done...
	 */
	return (count);

} /* static int string_count(char *strings[]) {...} */

/*
 * static int
 * keyword_locate(char *table[], int tableentries, char *keyword);
 *
 * Description:
 *	Locate a keyword in a table of keywords and returned the index to that
 *	keyword. This routines does a minimum match.
 *
 * Parameters:
 *	char *table[]
 *		Input - Pointer to the table of keywords.
 *
 *	int tableentries
 *		Input - Number of keywords in the table.
 *
 *	char *keyword
 *		Word to look up in the table.
 *
 * Return value:
 *	int	Index into the table of the keyword located. If there was no
 *		match, then return a negative value.
 */

static int
keyword_locate(const char *table[], int entries, char *keyword)
{
	/*
	 * Locals...
	 */
	const char	*tk;	/* Character in a table keyword.	*/
	const char	*tp;	/* Previous table keyword.		*/
	int		 index;	/* Index to table keyword.		*/
	int		 distance;	/* Distance to next entry.	*/
	int		 direction;	/* Which way to move.		*/

	/*
	 * Start in the middle of the table.
	 */
	distance	= (entries + 1) / 2;
	index		= distance - 1;
	tk		= table[index];

	/*
	 * While they don't match...
	 */
	while ((direction = strcasecmp(keyword, tk)) != 0) {

		/*
		 * Move half the distance each time.
		 */
		tp		 = tk;
		distance	 = (distance + 1) / 2;
		index		+= (direction < 0 ? -distance : distance);
		index		 = (index >= entries ? entries - 1 : index);
		index		 = (index < 0 ? 0 : index);
		tk		 = table[index];

		/*
		 * If the pointer did not move, then we don't have a match.
		 */
		if (tk == tp) {
			return (-1);

		} /* if (tk == tp) {...} */

		/*
		 * Are we ocilating?
		 */
		if (distance == 1) {

			/*
			 * No match in the table?
			 */
			if (strcasecmp(tk, keyword) > 0 &&
			    strcasecmp(tp, keyword) < 0) {
				return (-2);

			} /* if (*tk < *k && *k < *tp) {...} */

		} /* if (distance == 1) {...} */

	} /* while ((direction = strcasecmp(tk, keyword)) != 0) {...} */

	/*
	 * Found one.
	 */
	return (index);

} /* static int keyword_locate(char *table[], ..., char *keyword) {...} */

int
main(int argc, char *argv[])
{
	/*
	 * Static locals, their values must persist through recursion...
	 */
	static void	*ht = NULL;	/* Pointer to the table itself.	*/
	static keyword_t last_keyword;	/* Previous keyword seen.	*/
	static keyword_t this_keyword;	/* The keyword being processed.	*/
	static int	 keysize;	/* keysize for the table.	*/
	static ht_option_t options;	/* Hashtable options.	*/

	/*
	 * "Normal" locals...
	 */
	int	 numents;		/* # of entries in the table.	*/
	int	 kc;			/* Keyword count.		*/
	int	 ret;			/* Just a return value.		*/
	int	 mret;			/* Return value from main().	*/
	int	 mmret;			/* munmap return value.		*/
	char	*key;			/* Pointer to the key.		*/
	char	*data;			/* Pointer to the data.		*/
	char	*cdata;			/* Data to compare against.	*/
	int	 fd;			/* File descriptor...		*/
	struct stat fs;			/* Stats about the file.	*/
	char	*fc;			/* File contents.		*/
	char	*fl;			/* Line in the file.		*/
	char	*fn;			/* Next line in the file.	*/
	char	**fargv;		/* Vector from file.		*/
	char	**fargvt;		/* Current token in argv list.	*/
	char	**fargv2;		/* For resizing.		*/
	char	*ft;			/* Token in line.		*/
	struct	 inserted_data {
		struct	 inserted_data	*next;
		char			*key;
		char			*data;

	} *id = (struct inserted_data *)NULL;
	struct	inserted_data	*anchor = id;

	/*
	 * Values for parsing tokens from a file.
	 */
	static const char	f_token_separators[]	= " \n\t\r";
	size_t			 f_token_count		= 1;
	char			*argv0			= *argv;

	/*
	 * If not arguments, the print usage.
	 */
	if (argc < 2) {
		em(usage);
		return (EXIT_FAILURE);

	} /* if (argc < 2) {...} */

	/*
	 * Parse my arguments for commands of what do to.
	 */
	kc = string_count(keywords);
	last_keyword = k_max_;
	while (*++argv != (char *)NULL) {
		switch (this_keyword = keyword_locate(keywords, kc, *argv)) {
		case k_create: {
			/*
			 * -create <numents>
			 */
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameters ");
				em("<numents> <keysize> <options>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			numents = atoi(*argv);
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameters ");
				em("<keysize> <options>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			keysize	= atoi(*argv);
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameters ");
				em("<options>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			options	= atoi(*argv);
			info((this_keyword != last_keyword ? -1 : 0),
			    "ht_create(%d, %d, %d)\n",
			    numents,
			    keysize,
			    options);

			ht = ht_create(numents, keysize, options);
			if (ht == (void *)NULL) {
				em("**** Error: Create failed.\n");
				em("            errno = %d - %s\n",
				    errno,
				    strerror(errno));

				return (EXIT_FAILURE);

			} /* if (ht == (hashtable_t *)NULL) {...} */

			break;

		} /* case k_create: {...} */
		case k_delete: {
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameters ");
				em("<key>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			key	= *argv;
			info((this_keyword != last_keyword ? 0 : 1),
			    "ht_delete_key(ht, \"%s\")\n",
			    key);

			if (ht_delete_key(ht, key) == (void *)NULL) {
				em("**** Error: ht_delete_key(\"%s\") ", key);
				em("returned NULL, errno = %d - %s\n",
				    errno,
				    strerror(errno));

				return (EXIT_FAILURE);

			} /* if (ret = ht_delete_key(ht, key)) {...} */

			break;

		} /* case k_delete: {...} */
		case k_destroy: {
			info((this_keyword != last_keyword ? -1 : 0),
			    "ht_destroy(ht)\n");

			if (ret = ht_destroy(ht)) {
				em("**** Error: Destroy returned %d.\n", ret);
				em("            errno = %d - %s\n",
				    errno,
				    strerror(errno));
				return (EXIT_FAILURE);

			} /* if (ht_destroy(ht)) {...} */

			break;

		} /* case k_destroy: {...} */
		case k_file: {
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameters ");
				em("<filename>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			info((this_keyword != last_keyword ? -1 : 0),
			    "-file %s\n",
			    *argv);

			if ((fd = open(*argv, O_RDONLY)) < 0) {
				em("**** Error: open(%s, O_RDONLY) returned ",
				    *argv);

				em("returned %d, errno = %d - %s\n",
				    fd,
				    errno,
				    strerror(errno));

				return (EXIT_FAILURE);

			} /* if ((fd = open(*argv, O_RDONLY)) < 0) {...} */

			/*
			 * Get the size of the file.
			 */
			if ((ret = fstat(fd, &fs)) < 0) {
				em("**** Error: fstat(%d, fs) returned %d, ",
				    fd,
				    ret);

				em("errno = %d - %s\n",
				    errno,
				    strerror(errno));

				(void) close(fd);
				return (EXIT_FAILURE);

			} /* if ((ret = fstat(fd, fs)) < 0) {...} */

			/*
			 * mmap() the file.
			 */
			fc = mmap((void*)NULL,	/* Destination address.	*/
			    fs.st_size,	/* Len in bytes to map.	*/
			    PROT_WRITE | PROT_READ, /* Protect from others. */
			    MAP_PRIVATE,	/* Access mode.		*/
			    fd,			/* Which file?		*/
			    0);			/* Offset into file.	*/

			if (fc == (char *)MAP_FAILED) {
				em("**** Error: mmap(NULL, %ld, PROT_READ, ",
				    fs.st_size);

				em("MAP_PRIVATE, %d, 0) returned %p, ",
				    fd,
				    (void *) fc);

				em("errno = %d - %s.\n",
				    errno,
				    strerror(errno));

				(void) close(fd);
				return (EXIT_FAILURE);

			} /* if (ret < 0) {...} */

			/*
			 * Turn it into a vector of tokens (ala argv) and
			 * recurse on main().
			 */
			fargv = (char **)malloc((f_token_count + 2) *
			    sizeof (char *));

			if (fargv == (char **)NULL) {
				em("**** Error: malloc(%d) failed. ",
				    f_token_count * sizeof (char *));

				em("errno = %d - %s.\n",
				    errno,
				    strerror(errno));

				(void) munmap(fc, fs.st_size);
				(void) close(fd);
				return (EXIT_FAILURE);

			} /* if (fargv == (char **)NULL) {...} */

			/*
			 * Point fargv[0] at my program name.
			 */
			fargvt		= fargv;
			*fargvt++	= argv0;
			for (fl = fc; fl - fc < fs.st_size; fl = fn) {
				/*
				 * Find the next line.
				 */
				fn = eol(fl);
				*fn++ = '\0';

				/*
				 * Skip comment lines.
				 */
				if (*fl == '#') {
					continue;

				} /* if (*fl == '#') {...} */

				/*
				 * Fetch tokens from this line.
				 */
				ft = strtok(fl, f_token_separators);

				while (ft != (char *)NULL) {

					/*
					 * Make sure there is room for the
					 * token in the argv list.
					 */
					if (fargvt - fargv == f_token_count) {
						f_token_count *= 2;
						fargv2 = (char **)
						    realloc(fargv,
							(f_token_count + 2) *
							sizeof (char *));

						if (fargv2 == (char **)NULL) {
							em("**** Error: ");
							em("realloc(%d) ",
							    f_token_count *
							    sizeof (char *));

							em("failed. errno = ");
							em("%d - %s.\n",
							    errno,
							    strerror(errno));

							(void) munmap(fc,
							    fs.st_size);

							(void) free(fargv);
							(void) close(fd);
							return (EXIT_FAILURE);

						} /* if (... == NULL) {...} */

						/*
						 * Got the space. Move the
						 * current token pointer to the
						 * new buffer, then point the
						 * argv list to the new buffer.
						 */
						fargvt =
						    &fargv2[fargvt - fargv];

						fargv = fargv2;

					} /* if (... == f_token_count) {...} */

					/*
					 * I have the space. Stash the address
					 * of the token.
					 */
					*fargvt++ = ft;

					/*
					 * Scan for the next token in the line.
					 */
					ft = strtok((char *)NULL,
					    f_token_separators);

				} /* while (ft != (char *)NULL) {...} */

			} /* for (fl = fc; fl - fc < fs.st_size; ) {...} */

			/*
			 * Put a NULL at the end of the list.
			 */
			*fargvt++ = (char *)NULL;

			/*
			 * Got token? Recurse on main!
			 */
			if ((mret = main(fargvt - fargv, fargv)) != 0) {
				em("**** Error: main(%d, %p) returned %d.\n",
				    fargvt - fargv,
				    (void *) fargv,
				    ret);

				return (EXIT_FAILURE);

			} /* if ((ret = main(...)) != 0) {...} */

			/*
			 * All done. Free fargv, unmap and close the file.
			 */
			(void) free(fargv);

			if ((mmret = munmap(fc, fs.st_size)) != 0) {
				em("**** Error: munmap(%p, %ld) failed, ",
				    (void *) fc,
				    fs.st_size);

				em("errno = %d - %s\n",
				    errno,
				    strerror(errno));

			} /* if ((mmret = munmap(...)) != 0) {...} */

			if ((ret = close(fd)) != 0) {
				em("**** Error: close(%d) failed, ", fd);
				em("errno = %d - %s.\n",
				    errno,
				    strerror(errno));

			} /* if ((ret = close(fd)) != 0) {...} */

			if (ret != 0 || mmret != 0 || mret != 0) {
				return (EXIT_FAILURE);

			} /* if (ret != 0 || mmret != 0 || mret != 0) {...} */

			break;

		} /* case k_file: {...} */
		case k_ignore: {
			em("-ignore <count> not implemented yet.\n");
			return (EXIT_FAILURE);

		} /* case k_ignore: {...} */
		case k_insert: {
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameters ");
				em("<key> <data>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			key	= *argv;
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameters ");
				em("<data>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			data	= *argv;
			info((this_keyword != last_keyword ? 0 : 1),
			    "ht_insert(ht, \"%s\", \"%s\")\n",
			    key,
			    data);

			/*
			 * Allocate a buffer to hold the key and the data...
			 */
			id =
			    (struct inserted_data *)malloc(sizeof (*id) +
				keysize + 1 +
				strlen(data) + 1);

			if (id == (struct inserted_data *)NULL) {
				em("**** Error: malloc(%d) failed.\n",
				    sizeof (*id) +
				    keysize + 1 +
				    strlen(data) + 1);

				return (EXIT_FAILURE);

			} /* if (id == (struct inserted_data *)NULL) {...} */
			id->key = (void *)&id[1];
			(void) memcpy(id->key, key, keysize);
			id->key[keysize] = '\0';

			id->data = &id->key[keysize + 1];
			(void) memcpy(id->data, data, strlen(data));
			id->data[strlen(data)] = '\0';

			id->next	= anchor;
			anchor		= id;

			if (ret = ht_insert_key(ht, id->key, id->data)) {
				em("**** Error: ht_insert_key(%s, %s) ",
				    id->key,
				    id->data);

				em("returned %d, errno = %d - %s.\n",
				    ret,
				    errno,
				    strerror(errno));

				return (EXIT_FAILURE);

			} /* if (ret = ht_insert_key(ht, key, data)) {...} */

			break;

		} /* case k_insert: {...} */
		case k_locate: {
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameters ");
				em("<key> <data>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			key	= *argv;
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameters ");
				em("<data>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			data	= *argv;
			info((this_keyword != last_keyword ? 0 : 1),
			    "ht_locate(ht, \"%s\", \"%s\")\n",
			    key,
			    data);

			if ((cdata = ht_locate_key(ht, key)) == (void *)NULL) {
				em("**** Error: ht_locate_key(%s) ", key);
				em("returned NULL, errno = %d - %s.\n",
				    errno,
				    strerror(errno));

				return (EXIT_FAILURE);

			} /* if (ret = ht_locate_key(ht, key, data)) {...} */
			if (strcmp(data, cdata)) {
				em("**** Error: Data \"%s\" in table ",
				    cdata);

				em("does not match data \"%s\" in command.\n",
				    data);

				return (EXIT_FAILURE);

			} /* if (strcmp(data, cdata)) {...} */

			break;

		} /* case k_locate: {...} */
		case k_resize: {
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameters ");
				em("<numents>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			numents = atoi(*argv);
			info((this_keyword != last_keyword ? -1 : 0),
			    "ht_resize(ht, %d)\n",
			    numents);

			if (ret = ht_resize(ht, numents)) {
				em("**** Error: ht_resize(ht, %d) returned",
				    numents);
				em("%d - errno = %d - %s\n",
				    ret,
				    errno,
				    strerror(errno));

				return (EXIT_FAILURE);

			} /* if (ret = ht_resize(ht, numents)) {...} */

			break;

		} /* case k_resize: {...} */
		case k_verbose: {
			if (*++argv == (char *)NULL) {
				em("**** Error: Missing required parameter ");
				em("<level>\n");
				return (EXIT_FAILURE);

			} /* if (*++argv == (char *)NULL) {...} */
			verbose = atoi(*argv);
			info((this_keyword != last_keyword ? -1 : 0),
			    "verbose = %d\n",
			    verbose);

			break;

		} /* case k_verbose: {...} */
		default: {
			em("**** Error: Unrecognized argument \"%s\"\n",
			    *argv);
			return (EXIT_FAILURE);

		} /* default: {...} */

		} /* switch (keyword_locate(keywords, kc, *argv)) {...} */

		last_keyword = this_keyword;

	} /* while (argc-- && *argv != (char *)NULL) {...} */

	return (EXIT_SUCCESS);

} /* int main(int argc, char *argv[]) {...} */
