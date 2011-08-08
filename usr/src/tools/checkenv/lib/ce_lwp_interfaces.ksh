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
# ident	"@(#)ce_lwp_interfaces.ksh	1.3	07/01/04 SMI"
#

# 
# Function ce_lwp_interfaces
#
# This function checks if the system supports the ce_lwp_interfaces
#
function ce_lwp_interfaces
{
	typeset -l defined_undefined=${1}

	result=PASS
	resultmsg=

	# Check the argument and make sure it is as expected - abort
	# otherwise
	#
	errmsg="ce_lwp_interfaces expects argument of defined or undefined"

        [[ $# -ne 1 ]] && abort $errmsg
	[[ $1 != "defined" && $1 != "undefined" ]] && abort $errmsg

	# Set print information
	#
	req_label="lwp interfaces defined in libc"
	req_value="${defined_undefined}"

	# If operation is to dump info, dump and return
	[[ $OPERATION = "dump" ]] && {
		ce_lwp_interfaces_doc
		return $PASS
	}

	#
	# Verify that the system meets requirements - set result=[PASS|FAIL]
	#
	[[ $OPERATION = "verify" ]] && {
		nm /usr/lib/libc.so | grep __lwp_create | grep GLOB >/dev/null 2>&1
		res=$?
		[[ "${defined_undefined}" = "defined" ]]  && 
			[[ $res -ne 0 ]] && result=FAIL

		[[ "${defined_undefined}" = "undefined" ]]  && 
			[[ $res -eq 0 ]] && result=FAIL
		
	}
	
	# print results of checkenv
	print_line $TASK "$req_label" "$req_value" "$result"

	# return final result
	eval return \$$result
}

function ce_lwp_interfaces_doc
{
	cat >&1 << EOF

Check ce_lwp_interfaces ($TASK)
==================================
Description: 
	Check if this system supports _lwp interfaces (e.g. _lwp_create)
Arguments: 
	#1 - defined or undefined  (interaces are defined or undefined)
Requirement label (for this check): 
	$req_label
Requirement value (for this check): 
	$req_value
EOF
}
