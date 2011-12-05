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

################################################################################
#
# __stc_assertion_start
#
# ID: hotspare_onoffline_003_neg
#
# DESCRIPTION:
#	A hot spare may be made offline or online if it is currently active
#	as a spare, but not if it is an unused spare. Invoke "zpool offline"
#	and "zpool online" with this a hot spare. This will fail with a return
#	code of 1 if idle, and succeed if active.
#
# STRATEGY:
#	1. Create a storage pool with hot spares
#	2. Try 'zpool offline' & 'zpool online' with each hot spare in the
#	following states:
#		- only in the list of available hot spares (fail)
#		- have been activated (succeed)
#	3. Verify offline/online results as expected.
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING STATUS: COMPLETED (2006-06-07)
#
# __stc_assertion_end
#
###############################################################################

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

	log_mustnot $ZPOOL offline $TESTPOOL $dev
	log_must check_hotspare_state $TESTPOOL $dev "AVAIL"

	log_mustnot $ZPOOL online $TESTPOOL $dev
	log_must check_hotspare_state $TESTPOOL $dev "AVAIL"

	for odev in $pooldevs ; do
		log_must $ZPOOL replace $TESTPOOL $odev $dev
		while check_state "$TESTPOOL" "resilvering" "online" || \
		    ! is_pool_resilvered $TESTPOOL ; do
			$SLEEP 1
		done

		log_must $ZPOOL offline $TESTPOOL $dev
		log_must check_state $TESTPOOL $dev "offline"

		log_must $ZPOOL online $TESTPOOL $dev
		log_must check_state $TESTPOOL $dev "online"

		log_must $ZPOOL detach $TESTPOOL $dev
	done
}

log_assert "'zpool on/offline' against a hot spare works as expected"

log_onexit cleanup

set_devs

for keyword in "${keywords[@]}" ; do
	setup_hotspares "$keyword"

	iterate_over_hotspares verify_assertion

	destroy_pool "$TESTPOOL"
done

log_pass "'zpool on/offline' against a hot spare works as expected"
