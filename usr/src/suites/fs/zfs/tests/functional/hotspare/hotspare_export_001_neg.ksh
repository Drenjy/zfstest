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
# ident	"@(#)hotspare_export_001_neg.ksh	1.2	09/06/22 SMI"
#
. $STF_SUITE/tests/functional/hotspare/hotspare.kshlib

################################################################################
#
# __stc_assertion_start
#
# ID: hotspare_export_001_neg
#
# DESCRIPTION: 
#	If 2 storage pools have shared hotspares, if the shared hotspare was used by
#	one of the pool, the export of the pool that use hotspare will fail.
#
# STRATEGY:
#	1. Create 2 storage pools with hot spares shared.
#	2. Fail one vdev in one pool to make the hotspare in use.
#	3. Export the pool that currently use the hotspare
#	4. Verify the export will failed with warning message.
#	5. Verify export -f will success.
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING STATUS: COMPLETED (2008-12-12)
#
# __stc_assertion_end
#
###############################################################################

verify_runnable "global"

function cleanup
{

	if poolexists $TESTPOOL ; then 
		destroy_pool $TESTPOOL
	else
		$ZPOOL import -d /var/tmp -f | $GREP  \
			"pool: $TESTPOOL">/dev/null 2>&1
		if (( $? == 0 )); then
			log_must $ZPOOL import -d /var/tmp -f $TESTPOOL
			destroy_pool $TESTPOOL
		fi
	fi

	poolexists $TESTPOOL1 && \
		destroy_pool $TESTPOOL1

	partition_cleanup

}


log_onexit cleanup

function verify_assertion # type, dev
{
        typeset pool_type=$1
        typeset hotspare=$2

        typeset err_dev=${devarray[3]}
	typeset pool_dev="${devarray[6]}"
	typeset raidz2_dev="${devarray[4]}"
	typeset mntp=$(get_prop mountpoint $TESTPOOL)
 
	create_pool $TESTPOOL1 $pool_dev spare $hotspare

	# error out the $TESTPOOL to make spare in use
	log_must $RM -f $err_dev
	# do some IO on the fs $TESTPOOL
	log_must $DD if=/dev/zero of=$mntp/$TESTFILE0 bs=512 count=2048

	log_must $ZPOOL scrub $TESTPOOL

	$SYNC
	while is_pool_scrubbing $TESTPOOL ; do
		$SLEEP 2
	done

	if [[ $pool_type == "raidz2" ]]; then
		log_must $RM -f $raidz2_dev
	fi
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
	log_must $ZPOOL status $TESTPOOL1

	log_mustnot $ZPOOL export $TESTPOOL
	log_must $ZPOOL export -f $TESTPOOL

	log_must $ZPOOL import -d /var/tmp -f $TESTPOOL
	destroy_pool $TESTPOOL

	destroy_pool $TESTPOOL1

	log_must $MKFILE $SIZE $err_dev
	if [[ $pool_type == "raidz2" ]]; then
		log_must $MKFILE $SIZE $raidz2_dev
	fi
}

log_onexit cleanup

log_assert "export pool that using shared hotspares will fail"

set_devs

typeset share_spare="${devarray[0]}"
set -A my_keywords "mirror" "raidz1" "raidz2"

for keyword in "${my_keywords[@]}" ; do
        setup_hotspares $keyword $share_spare
        verify_assertion $keyword $share_spare
done

log_pass "export pool that using shared hotspares will fail"

