#! /usr/bin/ksh  -p
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
# Function ce_memtest
#
# Check whether or not the memtest driver is installed on the system
#
function ce_memtest
{
	typeset -l ce_memtest_arg=${1}

	typeset	result=PASS
	typeset memtest=""

	#
	# Check the argument and make sure it is as expected - abort
	# otherwise.
	#
	errmsg="ce_memtest expects argument of installed or uninstalled"
	[[ $# -ne 1 ]] && abort $errmsg
	[[ $1 != "installed" && $1 != "uninstalled" ]] && abort $errmsg

	req_label="MEMTEST"
	req_value="$ce_memtest_arg"

        # If operation is to dump usage info, dump and return
	[[ $OPERATION = "dump" ]] && {
		ce_memtest_doc
		return $PASS
	}

	#
	# Verify that the system meets requirements - set result=[PASS|FAIL]
	#
	# Checking if the memtest kernel module is loaded won't work because
	# often it won't get loaded until you use mtst for the first time.
	# Instead we will check if an entry has been added for it to
	# /etc/name_to_major.
	#
	[[ $OPERATION = "verify" ]] && {
		result=PASS

		memtest=`grep memtest /etc/name_to_major`

		[[ "$ce_memtest_arg" = "installed" ]]  && 
			[[ -z "$memtest" ]] && result=FAIL
		
		[[ "$ce_memtest_arg" = "uninstalled" ]]  && 
			[[ -n "$memtest" ]] && result=FAIL
	}

        print_line $TASK "$req_label" "$req_value" "$result"
	eval return \$$result
}

function ce_memtest_doc
{
	cat >&1 << EOF

Check ce_memtest ($TASK)
=========================
Description:
	Checks whether or not the memtest driver is installed
Arguments:
	#1 - installed or uninstalled(memtest driver is installed or uninstalled)
Requirement label (for this check):
	$req_label
Requirement value (for this check):
	$req_value
EOF
}
