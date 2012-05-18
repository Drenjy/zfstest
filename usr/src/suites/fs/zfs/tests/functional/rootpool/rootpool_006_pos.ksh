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
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
#

. $STF_SUITE/include/libtest.kshlib

#
# DESCRIPTION:
#
# the zfs rootfs's mountpoint must be mounted and must be /
#
# STRATEGY:
# 1) check if the current system is installed as zfs root 
# 2) get the rootfs
# 3) check the rootfs's mount ponit, it must be mounted and must be /
#

verify_runnable "global"
log_assert "zfs rootfs's mountpoint must be mounted and must be /"

typeset rootfs=$(get_rootfs)
typeset mountpoint=$(get_prop mountpoint $rootfs)
typeset mounted=$(get_prop mounted $rootfs)

if  [[ "$mountpoint" != "/" ]]; then
	log_note "${rootfs} mountpoint=$mountpoint"
	log_fail "rootpool ${rootfs}'s mountpoint is not /"
fi 

if  [[ "$mounted" != "yes" ]]; then
	log_note "${rootfs} mounted =$mounted"
	log_fail "rootfs's mounted property is not yes"
fi

log_pass "zfs rootfs's mountpoint must be mounted and must be /"
