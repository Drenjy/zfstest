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
# ident	"@(#)stf_configure.ksh	1.19	08/12/12 SMI"
#

(( ${#__DEBUG} > 0 )) &&
	[[ :${__DEBUG}: == *:stf_configure:* ]] && 
	set -o xtrace

trap "rm -f $STF_CONFIG/fail_list" 0 1 2 3 9 15 

me=`whence $0`
prog=${0##*/}
dir=`dirname $0`
inc=${dir%/bin/*}/include
typeset failure_list

. $inc/testgen.kshlib
. $inc/stf_common.kshlib

#
# Print out an error message and exit immediately
# if configuration fails.  We'll let stf_unconfigure
# worry about relevant cleanup
#
function config_failed {
	print -u2 "Test Suite Configuration: FAIL"
	print -u2 "Correct failures listed and re-run stf_configure"
	exit 1
}

typeset configure_usage="
Usage: $prog [ option ]

Options:
$STF_COMMON_OPTIONS_USAGE
	-l	   List mode
        -f file    Alternative configuration file
	-c var     Define config variable (e.g. -c \"STF_TIMEOUT=600\")
"

options=":lf:c:"
listmode=0
aconfigfile=
configvar=
newvar=

# 
# parse stf_configure specific options
# $1: option to parse, $2: option-argument
# return 0 (return any else will cause command to abort)
#
function parse_configure_options
{
	(( ${#__DEBUG} > 0 )) &&
	[[ :${__DEBUG}: == *:parse_configure_options:* ]] &&
	set -o xtrace

	typeset flag="$1"
	typeset optarg=""

	(( ${#2} > 0 )) && optarg="$2"
	
	case $flag in
		l)  listmode=1
		    ;;
		f)  [[ ! -f "$optarg" ]] && {
			_err  "File $optarg not found"
			exit 1
		    }
		    aconfigfile="${aconfigfile:+$aconfigfile} $optarg"
		    ;;

		c)  
		    newnam=$(echo $optarg | cut -d= -f1)
		    newval=$(echo $optarg | cut -d= -f2-)
		    newvar="${newnam}=\"${newval}\""
		    configvar="${configvar:+$configvar} $newvar"
		    ;;
	esac
	return 0
}

stf_parse_options "$options" parse_configure_options "$configure_usage" "$@"
shift $(($? - 1))

stf_init 
stf_process_formatstrings save

stf_needgosu=0
stf_parentdirs=$(stf_getparentdirs || echo $STF_SUITE) 

protodir=$STF_START_DIR
reldir=${protodir#$STF_SUITE}
reldir=${reldir%/}
reldir=${reldir#/}
builddir=$protodir/$STF_BUILD_MODE
configdir=$STF_CONFIG/$reldir

phase="CONFIGURE"

if [ ! -d $configdir ] ; then
	mkdir -m $STF_CONFIG_DIRMODE -p $configdir || config_failed
fi

typeset -i num=0
for file in $aconfigfile
do
	(( num += 1 ))
	nfile=$configdir/config.$$.$num
	cp $file $nfile 
	[[ $? -ne 0 ]] && {
		_err "Could not cp $file to config directory $configdir"
		rm -f $configdir/config.$$.*
		exit 1
	}
	nconfigfile="$nconfigfile $nfile"
done
aconfigfile=$nconfigfile

for dir in $stf_parentdirs ; do
	stf_needgosuindir $dir
	ret=$?
	if (( $ret == 1 )) ; then
		stf_needgosu=1
		break
	fi
done

if (( stf_needgosu == 0 )) ; then
	stf_needgosuintree $STF_START_DIR
	ret=$?
	stf_needgosu=$ret
fi

if (( $stf_needgosu == 1 && $listmode == 1)) ; then
	echo
	echo "This Test Suite Requires Root Access."
	echo "Configuring this test suite will prompt for the root password."
	echo
elif (( $stf_needgosu == 1 )) ; then
	stf_ensuregosu || config_failed
	# Checks for dynamically created root test cases are done later
fi

cd $configdir || config_failed

# source test tools config
[[ -f $STF_TOOLS/etc/stf_config ]] && \
    . $STF_TOOLS/etc/stf_config

# source test suite config
[[ -f $STF_SUITE/etc/stf_config ]] && \
    . $STF_SUITE/etc/stf_config

for dir in $stf_parentdirs ; do
	stf_configureindir -svkce $dir 
done
stf_configureindir -svkcegr $STF_START_DIR 

# Remove any user-specified (-f) config files that are temporarily
# stored in the config directory
rm -f $configdir/config.$$.*

echo "\n\nSUMMARY:"
if [ -f $STF_CONFIG/fail_list ]; then
	echo "Configuration failures occurred in the following directories:"
	cat $STF_CONFIG/fail_list | 
	while read faildir
	do
		echo "\t$faildir"
	done
	echo "\nTests in these directories won't run until the failures"\
		"are corrected"
	rm -f $STF_CONFIG/fail_list
	exit 1
else
	echo "No config phase failures detected"
	exit 0
fi	

# algorithm, parameter, configure env file
# check for need of gosu utility:
#	walk back to suite directory
#	for each directory from there back to pwd:
#		source test description file
#		check for root anything
#	for each directory from pwd to leaves,
#		source test description file
#		check for root anything
#	if root access is needed, build configure utility if it does
#	    not exist.  If in query mode, state that root is needed
# walk back to suite directory
# For each directory from there back to pwd:
#	source test description file
#	run configure script if it exists, passing target file and env file
#	    If in query mode, run checkenv -l
#	source configure target file if it exists
#	source test env file if it exists
#	run checkenv -c if it exists to verify environment
# For each subdir:
# 	create a subshell
#	do pwd stuff.
