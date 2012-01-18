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

# This script is intended to be used by STF Makefiles for determining
# various directory paths required for building, packaging and execution
# of STF-based software.
#
# This script is implemented as a set of ksh functions, each named
# after the STF variable whose value it calculates and prints.
#

function WS_ROOT
{
	((${#WS_ROOT} != 0)) && print ${WS_ROOT} && return 0

	#
	# Start in STF_PWD and traverse the directory tree upwards
	# level-by-level until the parent of src/{suites,tools} or
	# closed/{suites,tools} is reached.
	#
	typeset d=${STF_PWD}
	while [[ ! -d ${d}/src/suites ]] && \
		[[ ! -d ${d}/closed/suites ]] && \
		[[ ! -d ${d}/src/tools ]] && \
		[[ ! -d ${d}/closed/tools ]] && \
		[[ ${d:-"/"} != "/" ]];
	do
		d=${d%/*}
	done

	#
	# At this point, we have either reached WS_ROOT or WS_ROOT/usr
	# OR we are at "/"
	#
	[[ $d == "/" ]] && print "" || print ${d%/usr}
	return 0
}

function STF_SUITE
{
	#
	# Start in STF_PWD and traverse the directory tree upwards
	# until the parent of STF.INFO has been reached.
	#
	typeset d=${STF_PWD}
	while [[ ! -f ${d}/STF.INFO ]] && \
		[[ ${d:-"/"} != "/" ]];
	do
		d=${d%/*}
	done

	[[ $d == "/" ]] || [[ ! -f ${d}/STF.INFO ]] && print "" || print ${d}
	return 0
}

function STF_SUITE_PROTO
{
	#
	# STF_SUITE_PROTO is used only during build
	#
	# STF_SUITE_PROTO defines the proto dir corresponding to STF_SUITE
	# It is calculated in this function using a mapping of src dirs to
	# proto dirs.
	#
	typeset ws_root=$(WS_ROOT)
	typeset stf_suite=$(STF_SUITE)
	
	set -A src -- \
		src/suites src/tools \
		usr/src/suites usr/src/tools \
		usr/closed/suites usr/closed/tools

	set -A proto -- \
		proto/suites proto/tools

	#
	# For each src dir, the full path of the proto dir is formed by
	# replacing the path in the src array with the corresponding 
	# element from the proto array
	#
	typeset tail=${stf_suite#"$ws_root"}
	integer i=0
	
	for sd in ${src[*]}; do
		pt=${tail#"/${sd}/"}
		if [[ ${pt} != ${tail} ]]; then
			tail=${proto[`expr $i % 2`]}/${pt}
			break
		fi
		((i = i + 1))
	done
	print ${ws_root}/${tail}
	return 0
}

function STF_PKGARCHIVE
{
	((${#STF_PKGARCHIVE} != 0)) && print ${STF_PKGARCHIVE} && return 0

	print $(WS_ROOT)/packages && return 0
}

################################################################################
# main
################################################################################

# If no argument was supplied, print the null string and return
((${#1} == 0)) && print "" && return 0

# Ensure STF_PWD is set
((${#STF_PWD} == 0)) && STF_PWD=$(pwd)

# Evaluate the function corresponding to the requested variable
${1}

return 0
