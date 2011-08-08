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
# ident	"@(#)hotspare_replace_003_pos.ksh	1.2	09/06/22 SMI"
#
. $STF_SUITE/tests/functional/hotspare/hotspare.kshlib

################################################################################
#
# __stc_assertion_start
#
# ID: hotspare_replace_003_pos
#
# DESCRIPTION: 
#	If an active spare that itself fails, it should detach the failed one
#       and attatch a different spare in its place
#       
#
# STRATEGY:
#	1. Create 1 storage pools with hot spares
#	2. Fail one vdev in one pool to make 1 hotspare in use.
#	3. Error out the active hotspace
#	4. Verify the failed one was detatched while the other spare attatched.
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING STATUS: COMPLETED (2009-04-16)
#
# __stc_assertion_end
#
###############################################################################

verify_runnable "global"

function cleanup
{

	if poolexists $TESTPOOL ; then 
		destroy_pool $TESTPOOL
	fi

	partition_cleanup

}


log_onexit cleanup

function verify_assertion # type
{
        typeset pool_type=$1

        typeset err_dev=${devarray[3]}
	typeset raidz2_dev="${devarray[4]}"
	typeset mntp=$(get_prop mountpoint $TESTPOOL)
 
	# error out the $TESTPOOL to make fail_spare in use
	log_must $RM -f $err_dev

	# do some IO on the fs $TESTPOOL
	log_must $DD if=/dev/zero of=$mntp/$TESTFILE0 bs=512 count=2048

	log_must $ZPOOL scrub $TESTPOOL
	$SYNC
	while is_pool_scrubbing $TESTPOOL ; do
		$SLEEP 2
	done

	if [[ $pool_type == "raidz1" || $pool_type == "raidz2" ]]; then
		log_must $DD if=/dev/zero of=$mntp/$TESTFILE1 \
			bs=512 count=2048
	fi
	if [[ $pool_type == "raidz2" ]]; then
		log_must $ZPOOL scrub $TESTPOOL
		$SYNC
		while is_pool_scrubbing $TESTPOOL ; do
			$SLEEP 2
		done
	fi

	log_must $ZPOOL status $TESTPOOL
	log_must check_state $TESTPOOL "$fail_spare" \
			"INUSE     currently in use"

	# error out a spare to make the standby pool in use
	log_must  $RM -f $fail_spare

	# do some IO on the filesystem
	log_must $DD if=/dev/zero of=$mntp/$TESTFILE0 bs=512 count=2048

	$SYNC
	log_must $ZPOOL scrub $TESTPOOL
	while is_pool_scrubbing $TESTPOOL ; do
		$SLEEP 2
	done

	# check the zpool history will log when a spare device becomes active
	log_must $ZPOOL history -i $TESTPOOL | $GREP "internal vdev attach" | \
	$GREP "spare in vdev=$fail_spare for vdev=$err_dev" > /dev/null

	if [[ $pool_type == "raidz1" || $pool_type == "raidz2" ]]; then
		log_must $DD if=/dev/zero of=$mntp/$TESTFILE1 \
			bs=512 count=2048
	fi
	if [[ $pool_type == "raidz2" ]]; then
		log_must $ZPOOL scrub $TESTPOOL
		$SYNC
		while is_pool_scrubbing $TESTPOOL ; do
			$SLEEP 2
		done
	fi

	# do some IO on the filesystem
	log_must $DD if=/dev/zero of=$mntp/$TESTFILE1 bs=512 count=2048
	$SYNC
	log_must $ZPOOL scrub $TESTPOOL

	log_must $ZPOOL status $TESTPOOL

        # check if the standby spare in use, while the fail spare unavail
        log_must check_state $TESTPOOL $stand_spare "online"
        log_must check_state $TESTPOOL $stand_spare \
                                "INUSE     currently in use"
        log_mustnot check_state $TESTPOOL $fail_spare "online"

	# check the zpool history will log when a spare device becomes active
	log_must $ZPOOL history -i $TESTPOOL | $GREP "internal vdev attach" | \
		$GREP "spare in vdev=$stand_spare for vdev=$fail_spare" > /dev/null

	# do cleanup
	destroy_pool $TESTPOOL
	log_must $MKFILE $SIZE $err_dev
	log_must $MKFILE $SIZE $fail_spare
	
	if [[ $pool_type == "raidz2" ]]; then
		log_must $MKFILE $SIZE $raidz2_dev
	fi
}

log_onexit cleanup

log_assert "If one of the spare fail, the other available spare will be in use"

set_devs

typeset  fail_spare="${devarray[0]}"
typeset  stand_spare="${devarray[1]}"
typeset  spares="$fail_spare $stand_spare"

set -A my_keywords "mirror" "raidz1" "raidz2"

for keyword in "${my_keywords[@]}"; do
        setup_hotspares "$keyword" "$sparedevs"
        verify_assertion "$keyword"
done

log_pass "If one of the spare fail, the other available spare will be in use"

