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
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)ce_tool_exist.ksh	1.3	09/06/15 SMI"
#

# 
# Function ce_tool_exist
#
# This function checks if the system supports the ce_tool_exist
#
function ce_tool_exist
{
	tool=$1
	result=PASS
	resultmsg=

	# Check the argument and make sure it is as expected - abort
	# otherwise
	#
	errmsg="ce_tool_exist expects a tool name (to check) as an argument"

        [[ $# -ne 1 ]] && abort $errmsg

	# Set print information
	#
	req_label="tool must exist"
	req_value="$tool"

	# If operation is to dump info, dump and return
	[[ $OPERATION = "dump" ]] && {
		ce_tool_exist_doc
		return $PASS
	}

	#
	# Verify that the system meets requirements - set result=[PASS|FAIL]
	#
	[[ $OPERATION = "verify" ]] && {
		[[ ! -x $tool ]] &&  \
			result=FAIL && resultmsg="Tool $tool not found"
	}
	
	# print results of checkenv
	print_line $TASK "$req_label" "$req_value" "$result" "$resultmsg"

	# return final result
	eval return \$$result
}

function ce_tool_exist_doc
{
	cat >&1 << EOF

Check ce_tool_exist ($TASK)
==============================
Description: 
	Check if a tool exists
Arguments: 
	#1 - name of the tool
Requirement label (for this check): 
	$req_label
Requirement value (for this check): 
	$req_value
EOF
}
