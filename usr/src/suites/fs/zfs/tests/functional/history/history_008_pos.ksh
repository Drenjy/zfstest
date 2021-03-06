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

#
# Copyright (c) 2012 by Delphix. All rights reserved.
#

. $STF_SUITE/tests/functional/history/history_common.kshlib

#
# DESCRIPTION:
#	Pool history records all recursive operations.
#
# STRATEGY:
#	1. Create a filesystem and several sub-filesystems in it.
#	2. Make a recursive snapshot.
#	3. Verify pool history records all the recursive operations.
#	4. Do the same verification for hold, release, inherit, rollback and
#	   destroy.
#

verify_runnable "global"

function cleanup
{
	if datasetexists $root_testfs; then
		log_must $ZFS destroy -rf $root_testfs
	fi
	log_must $ZFS create $root_testfs
}

log_assert "Pool history records all recursive operations."
log_onexit cleanup

root_testfs=$TESTPOOL/$TESTFS
fs1=$root_testfs/fs1; fs2=$root_testfs/fs2; fs3=$root_testfs/fs3
for fs in $fs1 $fs2 $fs3; do
	log_must $ZFS create $fs
done

run_and_verify "$ZFS snapshot -r $root_testfs@snap" "-i"
run_and_verify "$ZFS hold -r tag $root_testfs@snap" "-i"
run_and_verify "$ZFS release -r tag $root_testfs@snap" "-i"
log_must $ZFS snapshot $root_testfs@snap2
log_must $ZFS snapshot $root_testfs@snap3
run_and_verify "$ZFS rollback -r $root_testfs@snap" "-i"
run_and_verify "$ZFS inherit -r mountpoint $root_testfs" "-i"
run_and_verify "$ZFS destroy -r $root_testfs" "-i"

log_pass "Pool history records all recursive operations."
