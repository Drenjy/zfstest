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
# ident	"@(#)ce_ipv6.ksh	1.3	07/01/04 SMI"
#

# 
# Function ce_ipv6
# 
# This function checks if the system is IPv6 enabled or not
#
function ce_ipv6
{
	typeset -l enabled_disabled=${1}

	result=PASS

	# Check the argument and make sure it is as expected - abort
	# otherwise.
	#
	errmsg="ce_ipv6 expects argument of enabled or disabled"
	[[ $# -ne 1 ]] && abort $errmsg

	[[ $1 != "enabled" && $1 != "disabled" ]] &&  abort $errmsg

	# Set req_label
	req_label="IPv6"
	req_value="$enabled_disabled"

	[[ $OPERATION = "dump" ]] && {
		ce_ipv6_doc
		return $PASS
	}

	#
	# Verify that the system meets requirements - set result=[PASS|FAIL]
	#
	[[ $OPERATION = "verify" ]] && {
		out=$(ifconfig -au6)
		[[ "$enabled_disabled" = "enabled" ]]  && 
			[[ -z "$out" ]] && result=FAIL
		
		[[ "$enabled_disabled" = "disabled" ]]  && 
			[[ -n "$out" ]] && result=FAIL
	}

	print_line $TASK "$req_label" "$req_value" "$result"
	eval return \$$result
}

function ce_ipv6_doc
{
	cat >&1 << EOF 

Check ce_ipv6 ($TASK)
========================
Description: 
	This check verifies if ipv6 is supported or not
Arguments: 
	#1 - enabled or disabled  (ipv6 is enabled or disabled)
Requirement label (for this check):   
	$req_label
Requirement value (for this check): 
	$req_value
EOF
}
