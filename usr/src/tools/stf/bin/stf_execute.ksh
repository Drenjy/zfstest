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
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

(( ${#__DEBUG} > 0 )) &&
	[[ :${__DEBUG}: == *:stf_execute:* ]] && 
	set -o xtrace

me=`whence $0`
prog=${0##*/}
dir=`dirname $0`
inc=${dir%/bin/*}/include
. $inc/stf_common.kshlib

typeset execute_usage="
Usage: $prog [ option ] [ tests ]

Options:
$STF_COMMON_OPTIONS_USAGE
	-i	   Execute in interactive mode (overrides -r and [ tests ])
	-c var	   Define config variable  (e.g. -c \"STF_TIMEOUT=600\")
	-m mode	   Execution mode (e.g. -m i386 or -m \"sparc sparcv9\")
		   Use \"-m list\" to list valid execution modes
	-r	   Force recursion (the default if no tests are specified)
Tests:
	Restrict execution to a list of tests or glob style patterns
	matching tests in the current directory.  This disables
	recursion to subdirectories.  Matches are made against the
	test names as they appear in the STF_*_TESTCASES definitions
	in the Makefile.  Use the -m option to further limit test
	execution to a specific mode.  Use the -r option to run
	matching tests in subdirectories in addition to the current
	directory.
" 	

options=":ic:m:r"
execute_mode=
execute_interactive=false
force_recurse=0
overall_fail=0
cnt=0
set -A varnames
set -A varvalues

# 
# parse stf_execute specific options
# $1: option to parse, $2: option-argument
# return 0 (return any else will cause command to abort)
#
function parse_execute_options
{
	(( ${#__DEBUG} > 0 )) &&
	[[ :${__DEBUG}: == *:parse_execute_options:* ]] &&
	set -o xtrace

	typeset flag="$1"
	typeset optarg=""
	(( ${#2} > 0 )) && optarg="$2"

	case $flag in
		m)   execute_mode=$optarg
		     ;;
		i)   execute_interactive=true
		     ;;
		r)   force_recurse=1
		     ;;
                c)   
		     varnames[$cnt]=$(echo $optarg | cut -d= -f1)
		     varvalues[$cnt]=$(echo $optarg | cut -d= -f2-)
		     (( cnt += 1 ))
		     ;;
	esac

	return 0
}

stf_parse_options "$options" parse_execute_options "$execute_usage" "$@"
shift $(($? - 1))

stf_init
stf_process_formatstrings load

test_list="$*"

stf_parentdirs=$(stf_getparentdirs)

protodir=$STF_START_DIR
reldir=${protodir#$STF_SUITE}
reldir=${reldir%/}
reldir=${reldir#/}
builddir=$protodir/$STF_BUILD_MODE
configdir=$STF_CONFIG/$reldir
configdir=${configdir%/}

# source test tools config
[[ -f $STF_TOOLS/etc/stf_config ]] && \
    . $STF_TOOLS/etc/stf_config

# source test suite config
[[ -f $STF_SUITE/etc/stf_config ]] && \
    . $STF_SUITE/etc/stf_config

# source test suite config for this directory
. $protodir/stf_description
. $configdir/stf_config.stf

# list the valid execution modes
if [[ ${execute_mode} == "list" ]]; then
	# get all the valid modes for this suite
	valid_modes=`$STF_TOOLS/build/stf_getmodelist \
		"$STF_EXECUTE_MODES" "" "$STF_DONTEXECUTE"`
	echo "Valid execution mode(s) for the current system:"
	echo "\t\"$valid_modes\""
	exit 0
fi

(( ${#execute_mode} > 0 ))  && STF_EXECUTEONLY=$execute_mode 

# limit execution modes to those selected by user
STF_SUITE_EXECUTE_MODES=`$STF_TOOLS/build/stf_getmodelist \
    	"$STF_EXECUTE_MODES" "$STF_EXECUTEONLY" "$STF_DONTEXECUTE"`

# convert mode strings to arrays
set -A mode_array $execute_mode
set -A stf_mode_array $STF_SUITE_EXECUTE_MODES

# check to see if modes specified on the command line are valid
if (( ${#stf_mode_array[*]} == 0 )) || (( ${#mode_array[*]} > 1 &&
	${#stf_mode_array[*]} != ${#mode_array[*]} )); then
	# get all the valid modes for this suite
	valid_modes=`$STF_TOOLS/build/stf_getmodelist \
		"$STF_EXECUTE_MODES" "" "$STF_DONTEXECUTE"`
	_err "Some or all mode values are invalid: \"$execute_mode\"" \
	"\nValid execution mode(s) for the current system:" \
	"\n\t\"$valid_modes\""
	exit 2
fi

# check if the specified cases exist 
if (( ${#test_list} > 0 )); then
	#
	# Scan the directory tree to get the matched paths($stf_match_paths) 
	# and the matched patterns($stf_exist_cases).
	#
	stf_scanindir "$STF_START_DIR"

	if (( $? != 0 )); then
		_err_exit 2 "Directory tree scan failed"
	fi

	#
	# $stf_match_paths contain the specified case paths are assigned 
	# in function stf_scanindir
	#
	if (( ${#stf_match_paths[@]} == 0 )); then
		_err_exit 2 "Could not find any of the specified test cases"
	fi

	#
	# When all the items in $test_list are found out and no duplicated in
	# original $test_list, $stf_exist_cases equals $test_list. 
	#
	if [[ "$stf_exist_cases" != "$test_list" ]]; then
		if [[ $test_list != \~* ]]; then
			#
			# Delete all of matched cases in original $test_list
			#
			while (( ${#back_list} != ${#test_list} )); do
				back_list=$test_list
				wordDelete_ "test_list" " " $stf_exist_cases
			done
			if (( ${#test_list} != 0 )); then
				_err "Could not find: " \"$test_list\"
			fi
		fi

		#
		# Filter non-existent and duplicate test cases
		#
		test_list="$stf_exist_cases"
	fi
fi

# use subshell so local env is not changed by execution
for STF_EXECUTE_MODE in $STF_SUITE_EXECUTE_MODES ; do
(
	exec_mode_fail=0
	abortexec=0
	export STF_EXECUTE_MODE

	if (( ${#STF_JNL_TAG_FORMAT} )) ; then
		stf_eval_formatstring STF_JNL_TAG_FORMAT
		export STF_JNL_TAG
	fi
	stf_eval_formatstring STF_JNL_NAME_FORMAT || exit 1
	stf_eval_formatstring STF_RESULTS_FORMAT || exit 1
	STF_RESULTS=$(absolutePath "$STF_RESULTS" "$STF_START_DIR")
	if [[ ! -d $STF_RESULTS ]] ; then
		if [[ "$STF_RESULTS_OPTION" == "-" ]] ; then
			_err "Results dir doesn't exist: \"$STF_RESULTS\""
			exit 1
		fi
		if ! mkdir -m $STF_RESULTS_DIRMODE -p "$STF_RESULTS" ; then
			_err "Could not make result dir: \"$STF_RESULTS\""
			exit 1
		fi
	fi
	STF_RESULTS=$(cd "$STF_RESULTS" && pwd -P)

	export STF_JOURNAL="$STF_RESULTS/$STF_JNL_NAME"

	STF_BUILD_MODE=`$STF_TOOLS/build/stf_configlookupexecmode ExecuteModes \
	    $STF_EXECUTE_MODE BUILD $STF_CONFIG_INPUTS`

	export STF_BUILD_MODE

	PATH=$STF_TOOLS/bin/$STF_BUILD_MODE:$PATH
	PATH=$STF_SUITE/bin/$STF_BUILD_MODE:$PATH
	export PATH

	LD_LIBRARY_PATH=$STF_TOOLS/lib/$STF_BUILD_MODE:$LD_LIBRARY_PATH
	LD_LIBRARY_PATH=$STF_TOOLS/contrib/lib/$STF_BUILD_MODE:$LD_LIBRARY_PATH
	LD_LIBRARY_PATH=$STF_SUITE/lib/$STF_BUILD_MODE:$LD_LIBRARY_PATH
	export LD_LIBRARY_PATH

	if [[ -e $STF_JOURNAL ]] ; then
		if [[ ! -d $STF_JOURNAL && -w $STF_JOURNAL ]] ; then
			case "$STF_JNL_NAME_OPTION" in
			!)	# clobber
				chmod $STF_JNL_FILEMODE "$STF_JOURNAL"
				> $STF_JOURNAL
				;;
			+)	# append
				;;
			*) 	# '-' (noclobber), this is the default behavior
				# abort the subshell, continue next loop		
				_err "$STF_EXECUTE_MODE: Journal file exists: "\
						"\"$STF_JOURNAL\""
				exit 1	
				;;
			esac
		else
			_err "$STF_EXECUTE_MODE: Not a writable file: "\
						"\"$STF_JOURNAL\""
					
			exit 1
		fi
	fi

	echo "\nJournal file: $STF_JOURNAL"
	echo "Execution mode: $STF_EXECUTE_MODE"
	echo "Configuration directory: $configdir"
	echo "Running from directory: $STF_START_DIR"

	VARFILE=/tmp/stf_varfile.$$; export VARFILE
	stf_jnl_start
	stf_jnl_env

	# source test tools mode config
	[[ -f $STF_TOOLS/etc/stf_config.$STF_EXECUTE_MODE ]] && \
		. $STF_TOOLS/etc/stf_config.$STF_EXECUTE_MODE

	# source test suite mode config
	[[ -f $STF_SUITE/etc/stf_config.$STF_EXECUTE_MODE ]] && \
		. $STF_SUITE/etc/stf_config.$STF_EXECUTE_MODE

	#
	# run setup scripts in parent directories
	# Create reverse parentdirs variable here so as to only
	# run cleanup on directories where setup was also run
	#
	stf_reverse_parentdirs=""
	for dir in $stf_parentdirs ; do
		stf_reverse_parentdirs="$dir $stf_reverse_parentdirs"
		stf_executeindir -vks $dir $STF_EXECUTE_MODE
		if (( $? != 0 )) ; then
			exec_mode_fail=1
			abortexec=1
			break
		fi
	done
	
	execute_flag=er
	if [[ $test_list != "" && $force_recurse == 0 ]] ; then
		# Do not recurse execution
		execute_flag=e
	fi
	if [[ $execute_interactive = true ]] ; then
		execute_flag=i
	fi

	#
	# run all tests in current directory and subdirs
	# unless parent setup failed earlier, in which case
	# we fall through to the cleanup section
	#
	if [[ $abortexec == 0 ]]; then
		stf_executeindir -vks${execute_flag}c $STF_START_DIR \
		    $STF_EXECUTE_MODE || exec_mode_fail=1
	fi

	# run cleanup in parents
	for dir in $stf_reverse_parentdirs ; do
		stf_executeindir -c $dir $STF_EXECUTE_MODE || exec_mode_fail=1
	done

	stf_jnl_end
	exit $exec_mode_fail
)
(( $? == 1 )) && overall_fail=1
done

exit $overall_fail
