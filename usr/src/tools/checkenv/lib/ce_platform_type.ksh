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
# ident	"@(#)ce_platform_type.ksh	1.2	07/01/04 SMI"
#

#
# Function ce_platform_type
#
# This function checks if system is of a particular platform type
#
# Args:
#	$1: platform (the platform type to check for)
#
function ce_platform_type
{
	platform=${1}

	result=PASS

	# Check the argument and make sure it is as expected - abort otherwise.
	errmsg="ce_platform_type expects an argument naming the platform type to check for (e.g. sparc)"
	[[ $# -ne 1 ]] && abort $errmsg

	# Set req values
	req_label="Required platform"
	req_value="$platform"

	# If operation is to dump info, dump and return
	[[ $OPERATION = "dump" ]] && {
		ce_platform_type_doc
		return $PASS
	}

	#
	# Verify that the system meets requirements - set result=[PASS|FAIL]
	#
	[[ $OPERATION = "verify" ]] && {
		[[ $(uname -p) != $platform ]] && {
			result=FAIL
			result_msg="platform type is $(uname -p), not $platform"
		}
	}

	print_line $TASK "$req_label" "$req_value" "$result" "$result_msg"
	eval return \$$result
}

function ce_platform_type_doc
{
	cat >&1 << EOF

Check ce_platform_type ($TASK)
=========================
Description:
	Check if a platform is installed on the system
Arguments:
	#1 - platform type (e.g. sparc, i386, amd64)
Requirement label (for this check):
	$req_label
Requirement value (for this check):
	$req_value
EOF
}
