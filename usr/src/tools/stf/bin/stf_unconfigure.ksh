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

me=`whence $0`
prog=${0##*/}
dir=`dirname $0`
inc=${dir%/bin/*}/include
. $inc/stf_common.kshlib

typeset unconfigure_usage="
Usage: $prog [ option ]

Options:
$STF_COMMON_OPTIONS_USAGE
"
options=""
stf_parse_options "$options" "" "$unconfigure_usage" "$@"
shift $(($? - 1))

stf_init 
stf_process_formatstrings load

stf_needgosu=0
stf_parentdirs=$(stf_getparentdirs)

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

protodir=$STF_START_DIR
reldir=${protodir#$STF_SUITE}
reldir=${reldir%/}
reldir=${reldir#/}
builddir=$protodir/$STF_BUILD_MODE
configdir=$STF_CONFIG/$reldir
#resultsdir=$STF_RESULTS/$reldir

phase="UNCONFIGURE"

if [[ ! -d $configdir ]] ; then
	mkdir -m $STF_CONFIG_DIRMODE -p $configdir || exit 1
fi
cd $configdir

# source test tools config
[[ -f $STF_TOOLS/etc/stf_config ]] && \
    . $STF_TOOLS/etc/stf_config

# source test suite config
[[ -f $STF_SUITE/etc/stf_config ]] && \
    . $STF_SUITE/etc/stf_config

# get environment from parents
for dir in $stf_parentdirs ; do
	stf_configureindir -se $dir
	if (( $? != 0 )) ; then
		print -u2 "Test Suite Unconfiguration Failed!"
		exit 1
	fi
done

# unconfigure in children, then in current directory
stf_configureindir -seru $STF_START_DIR
if (( $? != 0 )) ; then
	print -u2 "Test Suite Unconfiguration Failed!"
	exit 1
fi

stf_reverse_parentdirs=""
for dir in $stf_parentdirs ; do
    	stf_reverse_parentdirs="$dir $stf_reverse_parentdirs"
done

# unconfigure in parents
for dir in $stf_reverse_parentdirs ; do

	stf_configureindir -u $dir
	if (( $? != 0 )) ; then
                print -u2 "Test Suite Unconfiguration Failed!"
                exit 1
        fi
done

if (( $stf_needgosu == 1 )) ; then
	echo
	echo "Removing gosu utility"
	echo
	[[ -x $STF_GOSU ]] && $STF_GOSU /usr/bin/rm -f $STF_GOSU
fi

#remove configure directory

if [[ -d $configdir ]] ; then
	print "Removing configure directory"
	cd $STF_START_DIR
	/usr/bin/rm -fr $configdir
fi

exit 0
