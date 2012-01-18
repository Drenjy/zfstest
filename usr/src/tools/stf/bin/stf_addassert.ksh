#! /usr/bin/ksh -p
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

. ${STF_TOOLS}/include/stf_common.kshlib

function usage {
	cat >&2 <<-EOF
	Usage: $0 [-u root] <-t testname> -c <command to execute>
	  The -c switch MUST be the last switch on the line.
	  Tests execute as the user invoking the tests unless -u root specified.
	EOF
}

testname=""
typeset -i rootmode=0
typeset -i seen_t=0
typeset -i seen_c=0

while getopts ':h?u:t:c:' OPT ; do
	case $OPT in
		h)	usage
			exit 0
			;;
		u)
			[[ "$OPTARG" != "root" ]] && {
				print -u2 "The only alternate user currently" \
				    "supported is root."
				usage
				exit 1
			}
			#
			# It's possible that there was no indication
			# that we required root access until now, so
			# we'll make sure that stf_gosu exists
			#
			stf_ensuregosu || {
				print -u2 "Configure failed!"
				exit 1
			}
			rootmode=1
			;;
		t)	(( seen_t = 1 ))
			testname="$OPTARG"
			[[ -z "$testname" ]] && {
				print -u2 "t flag needs test name argument!"
				usage
				exit 1
			}
			;;
		c)	(( seen_c = 1 ))
			break
			;;
		\?)	# unknown option/action or -? for help
			[[ $OPTARG = '?' ]] && {
				usage
				exit 0
			}
			print -u2 "-$OPTARG: invalid option or action"
			exit 1
			;;
	esac
done

# 
# Grab command as everything else on the line past the -c switch
# This method leaves the developer free to insert whatever
# special control characters are needed, if desired
#
shift $(( OPTIND - ( 1 + seen_c ) ))

#
# Make sure that the command was called with sane arguments
# We must have a non-null test name as an argument and a command
# at the minimum
#
(( 0 == seen_t == seen_c )) && {
	usage
	exit 1
}

(( ${#@} == 0 )) && {
	print -u2 "Command was not listed!"
	usage
	exit 1
}
cmd="${@}"

#
# Now add the test cases to the testcases file
# For now the *private* file format is this:
#
# [testname] [free form command to run]
#
# The command can be in the standard test bin directory, in the
# current test directory, or can be a fully qualified path
#
# Currently there are two separate files, one for user level
# tests and one for root level tests.  The files themselves
# are not a supported interface.  The stf_addassert command is the
# proper way to add dynamic assertions. 
#
# This file format should eventually be architected and extended
# to include arbitrary users, as well as arbitrary privileges
# and other attributes.  A potential future format would be
# XML.  At this time, the user level file and root level file
# should be merged into one file.  For consistency with the
# rest of the current test framework, two files are now used
#
(( $rootmode )) && testcasefile="stf_root_testcases" || \
	testcasefile="stf_user_testcases"
echo "$testname\t$cmd" >> $testcasefile

exit 0
