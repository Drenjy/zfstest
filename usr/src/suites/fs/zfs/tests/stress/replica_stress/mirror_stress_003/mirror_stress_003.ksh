#!/usr/bin/ksh -p
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

. ${STF_SUITE}/include/libtest.kshlib
. ${STF_SUITE}/tests/stress/replica_stress/replica_stress_common.kshlib

#
# DESCRIPTION:
#	running multiple copies of zfs_dataset_create_write_destroy and
#       zfs_dataset_create_write_destroy_attr on separate mirrored pools
#       shall not cause the system to fail, hang or panic.
#
# STRATEGY:
#	the setup phase will have created several mirrored pools
#	multiple copies of zfs_dataset_create_write_destroy and 
#         zfs_dataset_create_write_destroy_attr are fired off
#	  one per mirror in the background
#	Wait for our stress timeout value to finish, and kill any remaining
#       tests.
#	The test is considered to have passed if the machine stays up during the
#       time the stress tests are running and doesn't hit the stf time limit.
#

log_assert "parallel dataset_create_write_destroy's and " \
        "dataset_create_write_destroy_exattr's on multiple mirrored " \
	"pools won't fail"

log_onexit cleanup

typeset pool=
typeset child_pids=
typeset stresslog=/tmp/${0##*/}.$$
typeset -i child=0

for pool in $(get_pools); do
	log_note "$CREATE_WRITE_DESTROY_SCRIPT $pool >$stresslog.$child"
	$CREATE_WRITE_DESTROY_SCRIPT $pool >$stresslog.$child 2>&1 &
	child_pids="$child_pids $!"
	(( child += 1 ))

	log_note "$CREATE_WRITE_DESTROY_EXATTR_SCRIPT $pool > " \
		"$stresslog.$child"
        $CREATE_WRITE_DESTROY_EXATTR_SCRIPT $pool > \
		$stresslog.$child 2>&1 &
	child_pids="$child_pids $!"
	(( child += 1 ))
done

#
# Monitor stress processes until they exit or timed out
#
stress_timeout $STRESS_TIMEOUT $child_pids

while (( child > 0 )); do
	(( child -= 1 ))
	log_must $RM -f $stresslog.$child
done

log_pass
