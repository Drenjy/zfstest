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
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
. $STF_SUITE/include/libtest.kshlib
. $STF_SUITE/tests/functional/cli_root/zpool_add/zpool_add.kshlib

#
# DESCRIPTION: 
# 	'zpool add <pool> <vdev> ...' can successfully add a zfs volume 
# to the given pool
#
# STRATEGY:
#	1. Create a storage pool and a zfs volume
#	2. Add the volume to the pool
#	3. Verify the devices are added to the pool successfully
#

verify_runnable "global"

function cleanup
{
	poolexists $TESTPOOL && \
		destroy_pool "$TESTPOOL"

	datasetexists $TESTPOOL1/$TESTVOL && \
		log_must $ZFS destroy -f $TESTPOOL1/$TESTVOL
	poolexists $TESTPOOL1 && \
		destroy_pool "$TESTPOOL1"	

	partition_cleanup

}

log_assert "'zpool add <pool> <vdev> ...' can add zfs volume to the pool." 

log_onexit cleanup

create_pool "$TESTPOOL" "${disk}s${SLICE0}"
log_must poolexists "$TESTPOOL"

create_pool "$TESTPOOL1" "${disk}s${SLICE1}"
log_must poolexists "$TESTPOOL1"
log_must $ZFS create -V $VOLSIZE $TESTPOOL1/$TESTVOL

log_must $ZPOOL add "$TESTPOOL" /dev/zvol/dsk/$TESTPOOL1/$TESTVOL

log_must iscontained "$TESTPOOL" "/dev/zvol/dsk/$TESTPOOL1/$TESTVOL"

log_pass "'zpool add <pool> <vdev> ...' adds zfs volume to the pool successfully"
