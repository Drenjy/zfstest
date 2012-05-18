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
# Copyright (c) 2011 by Delphix. All rights reserved.
#
. $STF_SUITE/tests/functional/hotspare/hotspare.kshlib

#
# DESCRIPTION:
#	If a hot spare have been activated,
#	and invoke "zpool detach" with this hot spare,
#	it will be returned to the set of available spares,
#	the original drive will remain in its current position.
#
# STRATEGY:
#	1. Create a storage pool with hot spares
#	2. Activate a spare device to the pool
#	3. Do 'zpool detach' with the spare in device
#	4. Verify the spare device returned to the set of available spares,
#		and the original drive will remain in its current position.
#

verify_runnable "global"

function cleanup
{
	poolexists $TESTPOOL && \
		destroy_pool $TESTPOOL

	partition_cleanup
}

function verify_assertion # dev
{
	typeset dev=$1

	for odev in $pooldevs ; do
		typeset -i fsize

		fsize=$(get_prop available $TESTPOOL)
		(( fsize = fsize * 3 / 4 ))

		log_must $MKFILE $fsize /$TESTPOOL/$TESTFILE1
		log_must $SYNC
		log_must $ZPOOL replace $TESTPOOL $odev $dev

		# It's possible (likely, even) for the resilvering to complete
		# before zpool status can complete. So wait for the resilvering
		# to finish, then check that it resilvered. In practice, this
		# while loop is never entered.
		while is_pool_resilvering; do
			$TRUE
		done
		log_must is_pool_resilvered "$TESTPOOL"
		log_must check_hotspare_state "$TESTPOOL" "$dev" "INUSE"

		log_must $ZPOOL detach $TESTPOOL $dev
		log_must check_hotspare_state "$TESTPOOL" "$dev" "AVAIL"
		log_must $RM -f /$TESTPOOL/$TESTFILE1
		log_must $SYNC
	done
}

log_assert "'zpool detach <pool> <vdev> ...' should deactivate the spared-in \
hot spare device successfully."

log_onexit cleanup

set_devs

for keyword in "${keywords[@]}" ; do
	setup_hotspares "$keyword"

	iterate_over_hotspares verify_assertion

	destroy_pool "$TESTPOOL"
done

log_pass "'zpool detach <pool> <vdev> ...' deactivate the spared-in hot \
spare device successfully."
