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

function usage {
	cat >&2 <<-EOF

Usage: $0 -t <testname> [-r <role>] -c <cmd> [-r <role>] [-c <cmd>] ...

  The -t argument must be provided first.

  Unline stf_addassert, -c takes a single argument, so the command to be
  invoked must be quoted.  However, the -c option may be present
  multiple times, and all specified commands will be executed
  concurrently when the test case runs.

  The -r option specifies the the role name of the machine on which any
  subsequently specified commands should run.  The default role name
  is SUT (System Under Test).

  All tests cases added via this command will execute as root, because
  the mstf_launch script runs as root.

  This command calls stf_addassert.
EOF
}

typeset -i seen_t=0
typeset -i seen_c=0
role="SUT"

while getopts ':h?t:c:r:' OPT ; do
	case $OPT in
		h)	usage
			exit 0
			;;
		r)	role="$OPTARG"
			[[ -z "$role" ]] && {
				print -u2 "r flag needs role name argument!"
				usage
				exit 1
			}
			;;
		t)	(( 1 == seen_t )) && {
				print -u2 "t flag may appear only once"
				usage
				exit 1
			}
			(( seen_t = 1 ))
			testname="$OPTARG"
			[[ -z "$testname" ]] && {
				print -u2 "t flag needs test name argument!"
				usage
				exit 1
			}
			add_command="stf_addassert -u root -t $OPTARG -c"
			add_command="$add_command mstf_launch $OPTARG"
			;;
		c)	(( seen_c = 1 ))
			command="$OPTARG"
			[[ -z "$command" ]] && {
				print -u2 "c flag needs a command argument!"
				usage
				exit 1
			}
			(( 0 == seen_t )) && {
				print -u2 "t flag must precede c flag!"
				usage
				exit 1
			}
			add_command="$add_command \\\"$role $command\\\""
			;;
		\?)	# unknown option/action or -? for help
			[[ $OPTARG = '?' ]] && {
				print -u2 "-$OPTARG: invalid option or action"
				usage
				exit 1
			}
			;;
	esac
done

(( 0 == seen_c )) && {
	print -u2 "At least one command must be specified via -c"
	usage
	exit 1
}

eval $add_command

exit 0
