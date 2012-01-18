#! /usr/bin/nawk -f
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

function usage() {
print "";
print "	Name:	configlookupTool";
print "";
print "	Syntax:";
print "		configlookupTool <intable> <arch> <mem> <file> <tool> {PATH|FLAGS} <config-file>";
print "";
print "	Parameters:";
print "		<intable>";
print "			Input - required";
print "			The name of the table to parse for the desired";
print "			information.";
print "";
print "		<arch>";
print "			Input - required";
print "			The name of the machine architecture for which";
print "			information should be searched.";
print "";
print "		<mem>";
print "			Input - required";
print "			The name of the memory model for which information";
print "			should be searched.";
print "";
print "		<file>";
print "			Input - required";
print "			The name of the file offset model for which";
print "			information should be searched.";
print "";
print "		<tool>";
print "			Input - required";
print "			The name of the compilation tool for which";
print "			information should be searched.";
print "";
print "		{PATH|FLAGS}";
print "			Input - required";
print "			A keyword specifying which information should be";
print "			returned from the table. Presently only the PATH and";
print "			FLAGS columns of the table are supported.";
print "";
print "		<config-file>";
print "			Input - required";
print "			This is the configuration file containing <intable>.";
print "";
print "	Description:";
print "";
print "		This utility searches <intable> for records matching <arch>,";
print "		<mem>, <file>, and <tool>, and returns the information from ";
print "		the columns specified by the keyword passed. At present ";
print "		<intable> is expected to be of the following format:";
print "";
print "		Arch.	Mem	File	Tool	Path	Flags/Directives";
print "";
}

#
# Function to print the desired column from the matching record.
#
function printcolumn() {
	gsub("{na}", "");
	if (tolower(outcolumn) ~ "build") {
		print $2;
	} else if (tolower(outcolumn) ~ "check") {
		n = 0;
		for (i = 3; i <= NF; i++) {
			if (n == 1)
				printf " ";
			printf "%s", $i;
			n = 1;
		}
		printf "\n"
	} else {
		exit(1);
	}
}

BEGIN {
#
# Must have all arguments or bail.
#
	if (ARGC < 4) {
		print "\n*** Error: Not enough arguments.";
		usage();
		exit(1);
	}

	table=		ARGV[1];	delete ARGV[1];	# Table to search.
	mode=		ARGV[2];	delete ARGV[2];	# Architecture.
	outcolumn=	ARGV[3];	delete ARGV[3];	# Column to print.

	found=		0;	# Found record.
	intable=	0;	# Start not-intable.
	nc=		0;	# Comment/blank lines.

	if (tolower(outcolumn) ~ "build") {

	} else if (tolower(outcolumn) ~ "check") {

	} else {
		usage();
		exit(1);
	}
}

#
# Skip comment and empty lines.
#
/^#/ || /^$/ || /^[[:space:]]+$/{ ++nc; next; }

#
# Concatenate continued lines.
#
/\\$/ {
	while ( $0 ~ /\\$/ ) {
		getline continued;
		$0 = substr($0, 1, index($0, "\\") - 1) continued;
	}
}

#
# Watch for the table of interest.
#
/%Table:/ && $2 ~ table ":" { intable = 1; next; }

#
# No longer in a table if we bump into another table heading.
#
/%Table:/ { intable = 0; }

#
# Don't bother parsing anything more if we're not in a table.
#
(intable == 0) { next; }

#
# And the record of interest in that table.
#
(intable == 1) && ($1 == mode) {
	printcolumn();
	found=1;
	exit(0);
}

#
# If we never saw a matching line, then print the information from the default 
# line. If we never even saw a default line, then error!
#
END {
	exit(found==0);
}
