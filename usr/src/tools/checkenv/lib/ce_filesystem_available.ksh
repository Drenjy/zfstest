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
# ident	"@(#)ce_filesystem_available.ksh	1.2	07/01/04 SMI"
#

#
# Function ce_filesystem_available
#
# This function checks that a specific filesystem is available and,
# optionally, that it has a specified amount of space available.
#
function ce_filesystem_available
{

	fs_name=$1
	typeset -i fs_space=$2

	result=PASS	
	resultmsg=

	errmsg="ce_filesystem_available supports 2 arguments (STC_FS, space required in Mb)"

        # Check the argument and make sure it is as expected - abort
	# otherwise.
	#
	[[ $# -eq 0 || $# -gt 2 ]] && abort $errmsg

	[[ -z "$fs_space" ]] && fs_space=0

	# Set requirement label information (field #2 of output)
	req_label="FS required (minimum Mb free)"

	# Set requirement label information 
	req_value="\$$fs_name ($fs_space Mb required)"

	# If operation is to dump info, dump and return
	[[ $OPERATION = "dump" ]] && {
		ce_filesystem_available_doc
		return $PASS
	}

	[[ $OPERATION = "verify" ]] && {

		typeset -i avail_k
		typeset -i avail_b
		typeset -i fs_space_b
		typeset -i free_space

		fs_name_value=$(eval echo \$${fs_name})
		print fs_name_value is $fs_name_value

		# First check that filesystem is mounted
		mount -p | awk '{print $3}' | grep "^${fs_name_value}$" > /dev/null 2>&1
		ret=$?
		if [[ $ret -ne 0 ]] 
		then
			result=FAIL
			resultmsg="filesystem ${fs_name_value} not a mounted filesystem"
		else
			avail_k=$(/bin/df -k ${fs_name_value} | \
				grep -iv capacity | awk '{print $4}') 	
			# convert to bytes 
			((avail_b = avail_k * 1000))
			((fs_space_b = fs_space * 1000000))
			let free_space=$avail_b-$fs_space_b
			if [[ $free_space -eq 0  ]] 
			then
				result=FAIL
				resultmsg="filesystem ${fs_name_value} does not have at least ${fs_space}MB available"
			fi
		fi
	}

	# print checkenv results
	print_line $TASK "$req_label" "$req_value" "$result" "$resultmsg"

	# return result code
	eval return \$$result
}

function ce_filesystem_available_doc
{
	cat >&1 << EOF

Check ce_filesystem_available ($TASK)
=====================================
Description:
	Test requires a mount filesystem.  Optionally disk space
	requirements can be checked.

Arguments:
	#1 - The filesystem that must be mount (e.g. /tmp)
	#2 - The amount of disk space that is required (optional)
Requirement label (for this check):
	$req_label
Requirement value (for this check):
	$req_value
EOF
}
