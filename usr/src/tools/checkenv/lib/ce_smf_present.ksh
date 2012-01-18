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

#
# Function:	ce_smf_present
# Purpose:	Verifies if SMF is present (functional) on the current system
#
function ce_smf_present
{
	result=$PASS

	req_label="SMF is present"
	req_value=""

	# If the request was to dump info, then dump and return
	if [[ $OPERATION = "dump" ]]; then
		ce_smf_present_doc
		return $result
	fi

	#
	# Verify that the system meets SMF requirements - set result=[PASS|FAIL]
	#
	if [[ $OPERATION = "verify" ]]; then
		# svccfg should run sanely on the system
		/usr/sbin/svccfg quit 2>&1
		[[ $? -ne 0 ]] && result=$FAIL
	fi

	print_line $TASK "$req_label" "$req_value" "$result"
	eval return \$$result
}

#
# Function:	ce_smf_present_doc
# Purpose:	Usage and readme documentation for this file
#
function ce_smf_present_doc
{
	# print a short purpose (usage) message if executing a task other than
	# "build."  Otherwise, print a longer message.
	#
	print "
Checkenv Library ce_smf_present ($TASK)
===============================
Description:	Check if SMF is present on the system
Arguments:	None
Requirement label (for this check): \"$req_label\"
Requirement value (for this check): \"$req_value\""


	if [[ $TASK == "BUILD" ]]; then
		print "
This library is intended for use in suites that wish to check
not only if SMF is *installed* on the current system, but also
that a basic level of functional sanity can be expected from
SMF on the target system.  This library should be invoked by
checkenv definition files at the 'top' of a test suite, or at
the top of a (set of) directory(ies) containing SMF-related
tests."
	fi

}
