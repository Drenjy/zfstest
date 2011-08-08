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
# ident	"@(#)stf_build.ksh	1.20	08/11/21 SMI"
#

(( ${#__DEBUG} > 0 )) &&
	[[ :${__DEBUG}: == *:stf_build:* ]] &&
	set -o xtrace

me=`whence $0`
prog=${0##*/}
dir=`dirname $0`
inc=${dir%/bin/*}/include
. $inc/stf_common.kshlib

typeset build_usage="
Usage: $prog [ option ] [ target ]
	
Options:
$STF_COMMON_OPTIONS_USAGE
	-n         Do not build subdirs
"

options=":n:" 
# 
# parse stf_build specific options 
# $1:   option to parse, option-argument is in $OPTARG 
# return 0 (return any else will cause command to abort) 
# 
function parse_build_options 
{ 
        (( ${#__DEBUG} > 0 )) && 
        [[ :${__DEBUG}: == *:parse_build_options:* ]] && 
        set -o xtrace 
 
        case $1 in 
                n) 
                        STF_DONT_BUILD_SUBDIRS=1 
                        export STF_DONT_BUILD_SUBDIRS 
                        ;; 
        esac 
 
        return 0 
} 
 
stf_parse_options "$options" parse_build_options "$build_usage" "$@" 

shift $(($? - 1))
stf_init 
stf_process_formatstrings

ARG=$1

if [[ "$ARG" == @(package|unpackage) ]] && ((${#STF_PKGARCHIVE} == 0)) ; then
	((${#WS_ROOT} == 0)) && \
		export WS_ROOT=`$STF_TOOLS/build/stf_getpath WS_ROOT`
	if ((${#WS_ROOT} == 0)); then
		print -u2 "Cannot set STF_PKGARCHIVE. Workspace not found."
		exit 1
	fi
	export STF_PKGARCHIVE=$WS_ROOT/packages
fi

((${#STF_SUITE_PROTO} == 0)) && \
	export STF_SUITE_PROTO=`$STF_TOOLS/build/stf_getpath STF_SUITE_PROTO`
if ((${#STF_SUITE_PROTO} == 0)); then
	print -u2 "Cannot determine STF_SUITE_PROTO. " \
			"Not inside an STF suite?"
	exit 1
fi 

STF_BUILD_CONFIG=`$STF_TOOLS/build/stf_create_Makefile.config \
		      ${STF_TOOLS}/etc "$STF_ALLBUILDMODES" $STF_CONFIG_INPUTS`

[[ "$ARG" = "" ]] && ARG=install

(( ${#__DEBUG} > 0 )) && [[ :${__DEBUG}: == *:stf_build:* ]] && flags=-dD

${MAKE:-/usr/ccs/bin/make} -e ${flags} $ARG

exit $?
