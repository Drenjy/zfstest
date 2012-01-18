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

. ${STF_TOOLS}/contrib/include/libsmf.shlib

typeset -i myid=`/usr/xpg4/bin/id -u`
if [ $myid -ne 0 ]; then
	echo "This test must be run by root Test Unresolved"
	exit 2
fi

typeset fname=smf_fmri_transition_state

echo "--INFO: Test the 'check' mode of the function '$fname'
	using the nfs/mapid service"

fmri="network/nfs/mapid:default"
timeout=5		# short, 5 second timeout

echo "--INFO: disable fmri using svcadm, then monitor the state change
	using function '$fname'"

svcadm disable $fmri
if [ $? -ne 0 ]; then
	echo "--DIAG: Error in svcadm disable Test Unresolved"
	exit 2
fi

tstate="disabled"
smf_fmri_transition_state "check" $fmri $tstate $timeout
if [ $? -ne 0 ]; then
	echo "--DIAG: FMRI '$fmri' did not transition to state $tstate
	within $timeout seconds Test Failed"
	exit 1
fi

echo "--INFO: enable fmri using svcadm, then monitor the state change
	using function '$fname'"

svcadm enable $fmri
if [ $? -ne 0 ]; then
	echo "--DIAG: Error in svcadm enable Test Unresolved"
	exit 2
fi

tstate="online"
smf_fmri_transition_state "check" $fmri $tstate $timeout
if [ $? -ne 0 ]; then
	echo "--DIAG: FMRI '$fmri' did not transition to state $tstate
	within $timeout seconds Test Failed"
	exit 1
fi


echo "--INFO: set maintenance state for $fmri using 'do' mode of 
	function '$fname', then invoke 'svcadm clear' and
	verify that the service returns to 'online' state"

smf_fmri_transition_state "do" $fmri maintenance $timeout
if [ $? -ne 0 ]; then
	echo "--DIAG: Could not set maintenance state for '$fmri'
Test Unresolved"
	exit 2
fi

svcadm clear $fmri
if [ $? -ne 0 ]; then
	echo "--DIAG: Could not clear maintenance state for '$fmri'
Test Unresolved"
	exit 2
fi

smf_fmri_transition_state "check" $fmri online $timeout
if [ $? -ne 0 -o "`smf_get_state $fmri`" = "maintenance" ]; then
	echo "--DIAG: Clear maintenance failed
		EXPECTED: current state of $fmri = online
		OBSERVED: current state of $fmri = `smf_get_state $fmri`
Test Failed"
	exit 1
fi

echo "Test Passed"
exit 0
