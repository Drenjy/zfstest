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
# ident	"@(#)checkenv.ksh	1.7	07/01/04 SMI"
#

export PASS=0
export FAIL=1
export ABORT=2

function errexit {
	print -u2 $* && exit $ABORT
}

function abort {
	(( num_ABORT = num_ABORT + 1 ))
	print -u2 ABORT: $*
	[[ -z "$KEEP_GOING" ]] && exit $ABORT
}

function print_line {
	
	type=$1

	[[ "$OUTPUT_TYPE" = "silent" ]] && return

	[[ "$OUTPUT_TYPE" = "error"  ]] && {
		[[ -n "$5" ]] && {
			[[ -z "${header_print}" ]]  && {
				print "The following checks failed:"
				header_print=TRUE
			}
			printf "\t- $5\n"
		}
		return
	}

	case $type in 

	START)  print "|$1|checkenv $2|"
		;;
	END)    print "|$1|checkenv $2|"
		;;
	FILE)   print "|$1|$2|"
		;;
	BUILD)  
		print -n "|$1|$2|$3|"
		[[ $OPERATION = "verify" ]] && {
			print -n "$4|"
			[[ -n "$5" ]] && print -n "$5|"
		}
		print
		;;
	CONFIGURE)  
		print -n "|$1|$2|$3|"
		[[ $OPERATION = "verify" ]] && {
			print -n "$4|"
			[[ -n "$5" ]] && print -n "$5|"
		}
		print
		;;
	EXECUTE)  
		print -n "|$1|$2|$3|"
		[[ $OPERATION = "verify" ]] && {
			print -n "$4|"
			[[ -n "$5" ]] && print -n "$5|"
		}
		print
		;;
	TOTAL)  print "|$1|PASS=$2 FAIL=$3 ABORT=$4|"
		;;
	esac
}

readonly PROG=$0
readonly ME=$(whence $PROG)
readonly FPATH_LOC=$(dirname ${ME})
readonly FPATH=$(dirname $FPATH_LOC)/lib

OPERATION=
OUTPUT_TYPE=verbose  # other options are "silent", "error" (error msg only)
SEARCHDIR=all
KEEP_GOING=
typeset -i num_PASS=0
typeset -i num_FAIL=0
typeset -i num_ABORT=0
typeset -u TASK=all

testsuite=$(pwd -P)
defsfile=checkenv_def

function usage
{
	cat >&2 << EOF
Usage: $PROG [ option ]

Options:
	-d	dump detailed information about requirements
	-e	run silently except when errors are encountered
	-f	checkenv definition file (default = checkenv_def)
	-h	print this message
	-k	keep going even if errors are encountered
	-l	list test requirements
	-s	run silently
	-t	task to verify ("build", "configure" or "execute")
	-T	test suite to check
	-v	verify test requirements
	-w	check requirements only in the current working directory
	-?	print this message
	
EOF
}

function save_results
{
        result=$1

        [[ $result -ne $PASS && $result -ne $FAIL ]] && abort "Invalid "\
                "result code returned to save_results (expected $PASS or $FAIL)"

        [[ $result -eq $PASS ]] && (( num_PASS = num_PASS + 1 ))
        [[ $result -eq $FAIL ]] && (( num_FAIL = num_FAIL + 1 ))
}

typeset opt

while getopts ':h?kdwesT:lf:vt:' opt
do
	case $opt in

	h)	usage
		exit $PASS
		;;
	f)	defsfile=$OPTARG
		;;
	l)	OPERATION=list
		;;
	v) 	OPERATION=verify
		;;
	d)	OPERATION=dump
		;;
	T) 	testsuite=$OPTARG
		;;
	t)	TASK=$OPTARG
		;;
	s) 	OUTPUT_TYPE=silent
		;;
	e) 	OUTPUT_TYPE=error
		header_print=
		;;
	k) 	KEEP_GOING=TRUE
		;;
	w) 	SEARCHDIR=pwd
		;;
	\?)	[[ $OPTARG = '?' ]] && {
			usage
			exit 0
		}
		print -u2 -- "-$OPTARG: invalid option or action"
		exit 1
		;;
	:)	print -u2 -- "-$OPTARG: option argument expected"
		exit 1
		;;
	esac
done

[[ ! -f "$testsuite"/"$defsfile" ]] && {
	print -u2 "Checkenv def file $testsuite/$defsfile does not exist"
	exit $ABORT
}

[[ -z "$OPERATION" ]] && {
	print -u2 "No operation specified - invalid usage"
	usage
	exit $ABORT
}

[[ "$OPERATION" = "verify"  ]]  && print_line START "-v"
[[ "$OPERATION" = "list"  ]]  && print_line START "-l"

# Set task_list
[[ $TASK = "ALL" || $TASK = "BUILD" ]] && task_list="$task_list BUILD"
[[ $TASK = "ALL" || $TASK = "CONFIGURE" ]] && task_list="$task_list CONFIGURE"
[[ $TASK = "ALL" || $TASK = "EXECUTE" ]] && task_list="$task_list EXECUTE"

envfiles=
# Look for all instances of checkenv
if [[ ${SEARCHDIR} = "pwd" ]] 
then
	[[ -f "$testsuite/$defsfile" ]]  && envfiles=$testsuite/$defsfile
else
	envfiles=$(find $testsuite/* -name "$defsfile")
fi

# check for "checkenv_defs" file in test suite root
for file in $envfiles
do
	case $OPERATION in

		"list")
			print_line FILE $file
			;;
		"verify")
			print_line FILE $file
			;;
		"dump")
			printf "\n\nChecks for file $file:\n"
			;;
	esac

	for task in $task_list
	do
		[ -f $file ] &&  . $file $task
	done
done

[[ $OPERATION = "verify" ]] && 
	print_line TOTAL $num_PASS $num_FAIL $num_ABORT

[[ $OPERATION = "list" || $OPERATION = "verify" ]] && {
	[[ "$OPERATION" = "verify"  ]]  && print_line END "-v"
	[[ "$OPERATION" = "list"  ]]  && print_line END "-l"
}

[[ $OPERATION = "list" || $OPERATION = "verify" ]] && {
	if [[ $num_FAIL -ne 0 ]] 
	then
		exit $FAIL
	else
		if [[ $num_ABORT -ne 0 ]]
		then
			exit $ABORT
		else
			exit $PASS
		fi
	fi
}
