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
# ident	"@(#)ce_is_system_labeled.ksh	1.1	07/08/03 SMI"
#

typeset errmsg=""

#
# Function:	check_labeling
# Purpose:	Checks if the current system has Trusted Extensions installed
#		and enabled
# Returns:	0, if TX is installed and enabled
#		1, if TX is not installed (implies not enabled)
#		2, if TX is installed, but not enabled
#		3, if TX is installed + enabled, but labeld is not online
#
function check_labeling
{
	TX_FILE=/usr/bin/plabel

	# Check if 'plabel' (Trusted Extensions) is installed
	if [[ ! -x $TX_FILE ]]; then
		errmsg="$req_label: Trusted Extensions not installed"
		return 1
	fi

	# Check if labeling (Trusted Extensions) is enabled
	$TX_FILE >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		errmsg="$req_label: Trusted Extensions not enabled"
		return 2
	fi

	# Check if labeling service is online
	FMRI="svc:/system/labeld:default"
	if [[ "online" != \
		"$(/usr/bin/svcprop -p restarter/state $FMRI 2>/dev/null)" ]];
	then
		errmsg="$req_label: $FMRI is not online"
		return 3
	fi

	return 0
}

#
# Function:	ce_is_system_labeled
# Purpose:	Verifies if labeling (Trusted Extensions) is enabled on the
#		current system
#
function ce_is_system_labeled
{
	result=$PASS

	req_label="System labeling check"
	req_value="none"

	# If the request was to dump info, then dump and return
	if [[ $OPERATION = "dump" ]]; then
		ce_is_system_labeled_doc
		return $result
	fi

	#
	# Check system labeling status - set result=[PASS|FAIL]
	#
	if [[ $OPERATION = "verify" ]]; then
		check_labeling >/dev/null 2>&1
		[[ $? -ne 0 ]] && result=$FAIL
	fi

	print_line $TASK "$req_label" "$req_value" "$result" "$errmsg"
	return $result
}

#
# Function:	ce_is_system_labeled_doc
# Purpose:	Usage and readme documentation for this file
#
function ce_is_system_labeled_doc
{
	# print a short message if executing a task other than "build."
	# Otherwise, print a longer message.
	#
	print "
Checkenv Library ce_is_system_labeled ($TASK)
===============================
Description:	Check if system labeling (Trusted Extensions) is enabled
Arguments:	None
Requirement label (for this check): \"$req_label\"
Requirement value (for this check): \"$req_value\""


	if [[ $TASK == "BUILD" ]]; then
		print "
This library is intended for use in suites that wish to check
not only whether Trusted Extensions packages are installed on
the current system, but also that system labeling has been 
enabled."
	fi
}
