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
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

. $STF_SUITE/include/libtest.kshlib

################################################################################
#
# __stc_assertion_start
#
# ID:  bootfs_002_neg
#
# DESCRIPTION:
#
# Invalid datasets are rejected as boot property values
#
# STRATEGY:
#
# 1. Create a snapshot and a zvol
# 2. Verify that we can't set the bootfs to those datasets
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING_STATUS: COMPLETED (2007-03-05)
#
# __stc_assertion_end
#
################################################################################

verify_runnable "global"

function cleanup {
	if snapexists $TESTPOOL/$FS@snap
	then
		$ZFS destroy $TESTPOOL/$FS@snap
	fi
	if datasetexists $TESTPOOL/$FS
	then
		log_must $ZFS destroy $TESTPOOL/$FS
	fi
	if datasetexists $TESTPOOL/vol
	then
		log_must $ZFS destroy $TESTPOOL/vol
	fi
	if poolexists $TESTPOOL
	then
		log_must $ZPOOL destroy $TESTPOOL
	fi
}


$ZPOOL set 2>&1 | $GREP bootfs > /dev/null
if [ $? -ne 0 ]
then
        log_unsupported "bootfs pool property not supported on this release."
fi

log_assert "Invalid datasets are rejected as boot property values"
log_onexit cleanup

DISK=${DISKS%% *}

log_must $ZPOOL create $TESTPOOL $DISK
log_must $ZFS create $TESTPOOL/$FS
log_must $ZFS snapshot $TESTPOOL/$FS@snap
log_must $ZFS create -V 10m $TESTPOOL/vol

if [[ $WRAPPER != *"smi"* ]] ; then
	log_mustnot $ZPOOL set bootfs=$TESTPOOL/$FS@snap $TESTPOOL
else
	log_must $ZPOOL set bootfs=$TESTPOOL/$FS@snap $TESTPOOL
fi
log_mustnot $ZPOOL set bootfs=$TESTPOOL/vol $TESTPOOL

log_pass "Invalid datasets are rejected as boot property values"
