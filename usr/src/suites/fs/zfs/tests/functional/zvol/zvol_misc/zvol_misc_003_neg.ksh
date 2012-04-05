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
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Copyright (c) 2012 by Delphix. All rights reserved.
#

. $STF_SUITE/include/libtest.kshlib
. $STF_SUITE/tests/functional/zvol/zvol_common.shlib

###############################################################################
#
# __stc_assertion_start
#
# ID: zvol_misc_003_neg
#
# DESCRIPTION:
#	Verify creating a storage pool or running newfs on a zvol used as a
#	dump device is denied.
#
# STRATEGY:
# 1. Create a ZFS volume
# 2. Use dumpadm to set the volume as dump device
# 3. Verify creating a pool & running newfs on the zvol returns an error.
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING_STATUS: COMPLETED (2008-01-07)
#
# __stc_assertion_end
#
################################################################################

verify_runnable "global"

function cleanup
{
	typeset dumpdev=$(get_dumpdevice)
	if [[ $dumpdev != $savedumpdev ]] ; then
		safe_dumpadm $savedumpdev
	fi

	if poolexists $TESTPOOL1 ; then
		destroy_pool $TESTPOOL1
	fi
}

log_assert "Verify zpool creation and newfs on dump zvol is denied."
log_onexit cleanup

voldev=/dev/zvol/dsk/$TESTPOOL/$TESTVOL
savedumpdev=$(get_dumpdevice)

safe_dumpadm $voldev

$ECHO "y" | $NEWFS -v $voldev > /dev/null 2>&1
if (( $? == 0 )) ; then
	log_fail "newfs on dump zvol succeeded unexpectedly"
fi

log_mustnot $ZPOOL create $TESTPOOL1 $voldev

log_pass "Verify zpool creation and newfs on dump zvol is denied."
