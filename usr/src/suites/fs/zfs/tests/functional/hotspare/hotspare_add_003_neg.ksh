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
# ident	"@(#)hotspare_add_003_neg.ksh	1.7	09/06/22 SMI"
#
. $STF_SUITE/tests/functional/hotspare/hotspare.kshlib

################################################################################
#
# __stc_assertion_start
#
# ID: hotspare_add_003_neg
#
# DESCRIPTION: 
# 'zpool add' with hot spares will fail
# while the hot spares belong to the following cases:
#	- nonexist device,
#	- part of an active pool,
#	- currently mounted,
#	- devices in /etc/vfstab,
#	- specified as the dedicated dump device,
#	- identical with the basic or spares vdev within the pool,
#	- belong to a exported or potentially active ZFS pool,
#	- a volume device that belong to the given pool,
#
# STRATEGY:
#	1. Create case scenarios
#	2. For each scenario, try to add [-f] the device to the pool
#	3. Verify the add operation failes as expected.
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING_STATUS: COMPLETED (2006-06-07)
#
# __stc_assertion_end
#
###############################################################################

verify_runnable "global"

function cleanup
{
	poolexists "$TESTPOOL" && \
		destroy_pool "$TESTPOOL"
	poolexists "$TESTPOOL1" && \
		destroy_pool "$TESTPOOL1"

	if [[ -n $saved_dump_dev ]]; then
		log_must $DUMPADM -u -d $saved_dump_dev
	fi

	cleanup_devices $dump_dev

	partition_cleanup
}

if ! $(is_physical_device $DISKS) ; then
	log_unsupported "This directory cannot be run on raw files."
fi

log_assert "'zpool add [-f]' with hot spares should fail with inapplicable scenarios."

log_onexit cleanup

set_devs
eval set -A poolarray $pooldevs

mnttab_dev=$(find_mnttab_dev)
vfstab_dev=$(find_vfstab_dev)
saved_dump_dev=$(save_dump_dev)
dump_dev=${disk}s0
nonexist_dev=${disk}s8

create_pool "$TESTPOOL" "${poolarray[0]}"
log_must poolexists "$TESTPOOL"

create_pool "$TESTPOOL1" "${poolarray[1]}"
log_must poolexists "$TESTPOOL1"

#	- nonexist device,
#	- part of an active pool,
#	- currently mounted,
#	- devices in /etc/vfstab,
#	- identical with the basic or spares vdev within the pool,

set -A arg "$TESTPOOL spare $nonexist_dev" \
	"$TESTPOOL spare ${poolarray[0]}" \
	"$TESTPOOL spare ${poolarray[1]}" \
	"$TESTPOOL spare $mnttab_dev" \
	"$TESTPOOL spare $vfstab_dev"

typeset -i i=0
while (( i < ${#arg[*]} )); do
	log_mustnot $ZPOOL add ${arg[i]}
	log_mustnot $ZPOOL add -f ${arg[i]}
	(( i = i + 1 ))
done

#	- specified as the dedicated dump device,
log_must $DUMPADM -u -d /dev/dsk/$dump_dev
log_mustnot $ZPOOL add "$TESTPOOL" spare $dump_dev
log_mustnot $ZPOOL add -f "$TESTPOOL" spare $dump_dev

#	- belong to a exported or potentially active ZFS pool,

log_must $ZPOOL export $TESTPOOL1
log_mustnot $ZPOOL add "$TESTPOOL" spare ${poolarray[1]}
log_must $ZPOOL import -d /var/tmp $TESTPOOL1

log_pass "'zpool add [-f]' with hot spares should fail with inapplicable scenarios."
