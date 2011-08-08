#!/bin/ksh -p
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
# ident	"@(#)cache_010_neg.ksh	1.1	08/05/14 SMI"
#

. $STF_SUITE/tests/functional/cache/cache.kshlib

#################################################################################
#
# __stc_assertion_start
#
# ID: cache_010_neg
#
# DESCRIPTION:
#	Verify cache device can only be disk or slice.
#
# STRATEGY:
#	1. Create a pool
#	2. Loop to add different object as cache
#	3. Verify it fails
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING_STATUS: COMPLETED (2008-04-24)
#
# __stc_assertion_end
#
################################################################################

verify_runnable "global"

function cleanup_testenv
{
	cleanup
	if [[ -n $lofidev ]]; then
		log_must $LOFIADM -d $lofidev
	fi
}

log_assert "Cache device can only be disk or slice."
log_onexit cleanup_testenv

dsk1=${DISKS%% *}
log_must $ZPOOL create $TESTPOOL ${DISKS#$dsk1}

# Add nomal disk
log_must $ZPOOL add $TESTPOOL cache $dsk1
log_must verify_cache_device $TESTPOOL $dsk1 'ONLINE'
# Add nomal file
log_mustnot $ZPOOL add $TESTPOOL cache $VDEV2

# Add lofi device
lofidev=${VDEV2%% *}
log_must $LOFIADM -a $lofidev
lofidev=$($LOFIADM $lofidev)
log_mustnot $ZPOOL add $TESTPOOL cache $lofidev
if [[ -n $lofidev ]]; then
	log_must $LOFIADM -d $lofidev
	lofidev=""
fi

#Add zvol
log_must $ZPOOL create $TESTPOOL2 $VDEV2
log_must $ZFS create -V $SIZE $TESTPOOL2/$TESTVOL
log_mustnot $ZPOOL add $TESTPOOL cache /dev/zvol/dsk/$TESTPOOL2/$TESTVOL

log_pass "Cache device can only be disk or slice."
