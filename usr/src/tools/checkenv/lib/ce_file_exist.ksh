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
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)ce_file_exist.ksh	1.3	09/06/15 SMI"
#

# 
# Function ce_file_exist
# 
# This function checks whether the file exists
#
function ce_file_exist
{
	print "checkenv: ce_file_exist($*)"

	errmsg="usage: ce_file_exist <absolute_file_name>"
	[ $# -ne 1 ] && abort $errmsg

	req_label="the file exists or not"
	req_value="exists"

	if [ $OPERATION == "dump" ]; then
		ce_file_exist_doc
		return $PASS
	fi

	result=FAIL
	if [ $OPERATION == "verify" ]; then
		if [[ -e $1 ]]; then 
			errmsg=""; result=PASS
		else
			errmsg="File $1 not found"
			result=FAIL
		fi
	fi

	print_line $TASK "$req_label" "$req_value" "$result" "$errmsg"
	eval return \$$result
}

function ce_file_exist_doc
{
	cat >&1 << EOF 

Check ce_file_exist
=================================
Description: 
	check whether the file exists or not
Arguments: 
	#1 - the absolute file name
Requirement label (for this check):   
	$req_label 
Requirement value (for this check): 
	$req_value
EOF
}
