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
	echo "This test must be run by root"
	echo "Test Unresolved"
	exit 2
fi

fname=smf_fmri_transition_state

echo "--INFO: Test the 'do' mode of the function '$fname'
	using the nfs/mapid service"

fmri="network/nfs/mapid:default"
timeout=5		# short 5 second timeout

echo "--INFO: disable $fmri"

tstate="disabled"

echo "--INFO: Invoke 'smf_fmri_transition_state \"do\" $fmri $tstate $timeout"
smf_fmri_transition_state "do" $fmri $tstate $timeout
if [ $? -ne 0 ]; then
	echo "--DIAG: Could not transition FMRI '$fmri' to state '$tstate'
Test Failed"
	exit 1
fi

curstate="`smf_get_state $fmri`"
if [ "$curstate" != "$tstate" ]; then
	echo "--DIAG: State transition failed
		EXPECTED: state of fmri '$fmri' is '$tstate'
		OBSERVED: state of fmri '$fmri' is '$curstate'
Test Failed"
	exit 1
fi

echo "--INFO: enable $fmri"

tstate="online"

echo "--INFO: Invoke 'smf_fmri_transition_state \"do\" $fmri $tstate $timeout"
smf_fmri_transition_state "do" $fmri $tstate $timeout
if [ $? -ne 0 ]; then
	echo "--DIAG: Could not transition FMRI '$fmri' to state '$tstate'
Test Failed"
	exit 1
fi

curstate="`smf_get_state $fmri`"
if [ "$curstate" != "$tstate" ]; then
	echo "--DIAG: State transition failed
		EXPECTED: state of fmri '$fmri' is '$tstate'
		OBSERVED: state of fmri '$fmri' is '$curstate'
Test Failed"
	exit 1
fi

echo "--INFO: Put $fmri in maintenance state"

tstate="maintenance"

echo "--INFO: Invoke 'smf_fmri_transition_state \"do\" $fmri $tstate $timeout'"
smf_fmri_transition_state "do" $fmri $tstate $timeout
if [ $? -ne 0 ]; then
	echo "--DIAG: Could not transition FMRI '$fmri' to state '$tstate'
Test Failed"
	exit 1
fi

curstate="`smf_get_state $fmri`"
if [ "$curstate" != "$tstate" ]; then
	echo "--DIAG: State transition failed
		EXPECTED: state of '$fmri' is '$tstate'
		OBSERVED: state of '$fmri' is '$curstate'
Test Failed"
	exit 1
fi

echo "--INFO: Setup $fmri to be restarted"

tstate="restart"

# Note that 'restart' is not really a valid "state".
# It *is* a valid state transition.

echo "--INFO: Invoke 'smf_fmri_transition_state \"do\" $fmri $tstate $timeout'"
smf_fmri_transition_state "do" $fmri $tstate $timeout
if [ $? -ne 0 ]; then
	echo "--DIAG: Could not transition FMRI '$fmri' to state '$tstate'
Test Failed"
	exit 1
fi

# an fmri in maintenance continues to be in maintenance even after restart
curstate="`smf_get_state $fmri`"
if [ "$curstate" != "maintenance" ]; then
	echo "--DIAG: State transition failed
		EXPECTED: state of '$fmri' is '$maintenance'
		OBSERVED: state of '$fmri' is '$curstate'
Test Failed"
	exit 1
fi

echo "--INFO: Clear maintenance state"

tstate="clear"

# Note that 'clear' is not really a valid "state".
# It *is* a valid state transition.

echo "--INFO: Invoke 'smf_fmri_transition_state \"do\" $fmri $tstate $timeout'"
smf_fmri_transition_state "do" $fmri $tstate $timeout
if [ $? -ne 0 ]; then
	echo "--DIAG: Could not clear maintenance state on '$fmri'
Test Failed"
	exit 1
fi

# After 'clear',  the fmri should have been restarted and should be online
curstate="`smf_get_state $fmri`"
if [ "$curstate" != "online" ]; then
	echo "--DIAG: State transition failed
		EXPECTED: state of '$fmri' is not 'maintenance'
		OBSERVED: state of '$fmri' is '$curstate'
Test Failed"
	exit 1
fi

echo "Test Passed"
exit 0
