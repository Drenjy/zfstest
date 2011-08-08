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
# ident	"@(#)hotspare_create_001_neg.ksh	1.5	09/06/22 SMI"
#
. $STF_SUITE/tests/functional/hotspare/hotspare.kshlib

################################################################################
#
# __stc_assertion_start
#
# ID: hotspare_create_001_neg
#
# DESCRIPTION:
# 'zpool create [-f]' with hot spares will fail 
# while the hot spares belong to the following cases:
#	- existing pool
#	- nonexist device,
#	- part of an active pool,
#	- currently mounted,
#	- devices in /etc/vfstab,
#	- specified as the dedicated dump device,
#	- identical with the basic vdev within the pool,
#
# STRATEGY:
# 1. Create case scenarios
# 2. For each scenario, try to create a new pool with hot spares 
# 	of the virtual devices
# 3. Verify the creation is failed.
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING_STATUS: COMPLETED (2006-06-07)
#
# __stc_assertion_end
#
################################################################################

verify_runnable "global"

function cleanup
{
	for pool in $TESTPOOL $TESTPOOL1
	do
		destroy_pool $pool
	done

	if [[ -n $saved_dump_dev ]]; then
		log_must $DUMPADM -u -d $saved_dump_dev
	fi

	partition_cleanup
}

if ! $(is_physical_device $DISKS) ; then
	log_unsupported "This directory cannot be run on raw files."
fi

log_assert "'zpool create [-f]' with hot spares should be failed " \
	"with inapplicable scenarios."
log_onexit cleanup

set_devs
eval set -A poolarray $pooldevs

mnttab_dev=$(find_mnttab_dev)
vfstab_dev=$(find_vfstab_dev)
saved_dump_dev=$(save_dump_dev)
dump_dev=${disk}s0
nonexist_dev=${disk}s8

create_pool "$TESTPOOL" ${poolarray[0]}

#
# Set up the testing scenarios parameters
#	- existing pool
#	- nonexist device,
#	- part of an active pool,
#	- currently mounted,
#	- devices in /etc/vfstab,
#	- identical with the basic vdev within the pool,

set -A arg "$TESTPOOL ${poolarray[1]} spare ${poolarray[2]}" \
	"$TESTPOOL1 ${poolarray[1]} spare $nonexist_dev" \
	"$TESTPOOL1 ${poolarray[1]} spare ${poolarray[0]}" \
	"$TESTPOOL1 ${poolarray[1]} spare $mnttab_dev" \
	"$TESTPOOL1 ${poolarray[1]} spare $vfstab_dev" \
	"$TESTPOOL1 ${poolarray[1]} spare ${poolarray[1]}"

typeset -i i=0
while (( i < ${#arg[*]} )); do
	log_mustnot $ZPOOL create ${arg[i]}
	log_mustnot $ZPOOL create -f ${arg[i]}
	(( i = i + 1 ))
done

# now destroy the pool to be polite
log_must $ZPOOL destroy -f $TESTPOOL

# create/destroy a pool as a simple way to set the partitioning
# back to something normal so we can use this $disk as a dump device
cleanup_devices $dump_dev

#
#	- specified as the dedicated dump device,
#
log_must $DUMPADM -u -d /dev/dsk/$dump_dev
log_mustnot $ZPOOL create $TESTPOOL1 ${poolarray[1]} spare "$dump_dev"
log_mustnot $ZPOOL create -f $TESTPOOL1 ${poolarray[1]} spare "$dump_dev"

log_pass "'zpool create [-f]' with hot spare is failed as expected with inapplicable scenarios."
