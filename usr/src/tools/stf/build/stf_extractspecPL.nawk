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

#
# Extract STC .spec file contents from the comments in a C source file.
#

BEGIN {
	in_assertion		= 0;
	assertion_seen		= 0;
	description_seen	= 0;
	interfaces_seen		= 0;
	strategy_seen		= 0;
}

#
# End of the .spec content.
#
/^# +end +__stf_assertion/ {
	in_assertion = 0;
	next;

}

#
# Beginning of the .spec content.
#
/^# +start +__stf_assertion__/ {
	in_assertion = 1;
	next;

}

#
# Eliminate /* and */ from the first and last lines.
#
#/^\/\*.*$/	{next}
#/^ *\*\/.*$/	{next}

#
# Assertion name. At least one is required by STC in every .spec file.
#
/^.+ASSERTION:/ && (in_assertion) {
	print "ASSERTION: " \
	    substr($0, index($0, "ASSERTION:") + length("ASSERTION:"));

	assertion_seen = 1;
	next;

}

#
# Actual assertion statement. STC calls this the description and requires one
# for every ASSERTION:.
#
/^.+DESCRIPTION:/ && (in_assertion) {
	print "DESCRIPTION: " \
	    substr($0, index($0, "DESCRIPTION:") + length("DESCRIPTION:"));

	description_seen = 1;
	next;

}

#
# List of interfaces targeted by the current assertion. STC requires one of
# these for every ASSERTION:
#
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
#
# Body of the assertion comments.
#
(in_assertion) && length {
	print substr($0,index($0,"#")+1);

}

#
# End of the soruce file. Anything to do?
#
END {
	if (! assertion_seen) {
		print "**** Warning: No ASSERTION: statement seen.";

	}

	if (! description_seen) {
		print "**** Warning: No DESCRIPTION: statement seen.";

	}

	if (! interfaces_seen) {
		print "**** Warning: No INTERFACES: statement seen.";

	}
	if (! strategy_seen) {
		print "**** Warning: No STRATEGY: statement seen.";

	}

	if (! (strategy_seen && assertion_seen && description_seen && interfaces_seen)) {
		exit(1);

	}


}
