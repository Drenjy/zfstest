#! /usr/xpg4/bin/awk -f
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

#
# Extract STC .spec file contents from the comments in a C source file.
#

function nothing_seen() {
  in_assertion			= 0;
  assertion_seen		= 0;
  description_seen		= 0;
  interfaces_seen		= 0;
  strategy_seen			= 0;
  testability_seen		= 0;
  author_seen			= 0;
  approvals_reviewers_seen	= 0;
  status_seen			= 0;
  comments_seen			= 0;

}

BEGIN {
  assertion_count	= 0;

}

#
# End of the .spec content.
#
/^#endif/ {
in_assertion = 0;
if (! assertion_seen) {
  print "**** Warning: No ASSERTION: statement seen.";
 
}
if (! description_seen) {
  print "**** Warning: No DESCRIPTION: statement seen.";

}
#if (! interfaces_seen) {
#  print "**** Warning: No INTERFACES: statement seen.";

#}
if (! strategy_seen) {
  print "**** Warning: No STRATEGY: statement seen.";

}
if (! testability_seen) {
  print "**** Warning: No TESTABILITY: statement seen.";

}
if (! author_seen) {
  print "**** Warning: No AUTHOR: statement seen.";

}
if (! approvals_reviewers_seen) {
  print "**** Warning: No APPROVAL/REVIEWERS: statement seen.";

}
if (! status_seen) {
  print "**** Warning: No STATUS: statement seen.";

}
if (! comments_seen) {
  print "**** Warning: No COMMENTS: statement seen.";

}

next;

}

#
# Beginning of the content.
#
/^#ifdef[[:space:][:blank:]]+__stc_assertion__/ {
	nothing_seen();
	in_assertion = 1;
	next;

}
/^#if[[:space:][:blank:]]+defined\(__stc_assertion__\)/ {
	nothing_seen();
	in_assertion = 1;
	next;

}

#
# Eliminate /* and */ from the first and last lines.
#
/^\/\*.*$/	{next}
/^ *\*\/.*$/	{next}

/^.+ASSERTION:/ && (in_assertion) {
	if (assertion_count > 0) {
		print "-------------------------------------------------------";

	}
	++assertion_count;

	print "ASSERTION: " \
		substr($0, index($0, "ASSERTION:") + length("ASSERTION:"));

	assertion_seen = 1;
	next;

}

/^.+DESCRIPTION:/ && (in_assertion) {
	print "DESCRIPTION: " \
	    substr($0, index($0, "DESCRIPTION:") + length("DESCRIPTION:"));

	description_seen = 1;
	next;

}

/^.+INTERFACES:/ && (in_assertion) {
	print "INTERFACES: " \
	    substr($0, index($0, "INTERFACES:") + length ("INTERFACES:"));

	interfaces_seen = 1;
	next;

}

/^.+STRATEGY:/ && (in_assertion) {
        print "STRATEGY: " \
            substr($0, index($0, "STRATEGY:") + length("STRATEGY:"));

        strategy_seen = 1;
        next;

}
/^.+TESTABILITY:/ && (in_assertion) {
        print "TESTABILITY: " \
            substr($0, index($0, "TESTABILITY:") + length("TESTABILITY:"));

        testability_seen = 1;
        next;

}
/^.+AUTHOR:/ && (in_assertion) {
        print "AUTHOR: " \
            substr($0, index($0, "AUTHOR:") + length("AUTHOR:"));

        author_seen = 1;
        next;

}
/^.+APPROVALS\/REVIEWERS:/ && (in_assertion) {
        print "APPROVALS\/REVIEWERS: " \
	substr($0, index($0, "APPROVALS\/REVIEWERS:") + length("APPROVALS\/REVIEWERS:"));

        approvals_reviewers_seen = 1;
        next;

}
/^.+STATUS:/ && (in_assertion) {
        print "STATUS: " \
            substr($0, index($0, "STATUS:") + length("STATUS:"));

        status_seen = 1;
        next;

}
/^.+COMMENTS:/ && (in_assertion) {
        print "COMMENTS: " \
            substr($0, index($0, "COMMENTS:") + length("COMMENTS:"));

        comments_seen = 1;
        next;

}
#
# Body of the assertion comments.
#
(in_assertion) && length {
	print substr($0,index($0,"*")+1);

}

#
# End of the soruce file. Anything to do?
#
END {
	if (assertion_count > 0) {
		print "-------------------------------------------------------";

	}

}
