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
# ident	"@(#)user_configure.ksh	1.1	07/10/09 SMI"
#

. $STF_SUITE/include/libtest.kshlib

# Before we do anything, verify that the user running the tests doesn't
# have "ZFS File System Management" or "ZFS Storage Management"
# profiles

PROFILES=$(/usr/bin/profiles)
FS_PROF=$(echo $PROFILES | /usr/bin/grep "ZFS File System Management")
POOL_PROF=$(echo $PROFILES | /usr/bin/grep "ZFS Storage Management")

if [ -n "$POOL_PROF" ] || [ -n "$FS_PROF" ]
then
	log_note "User profiles include $PROFILES"
        log_fail "Test suite user already has ZFS profile. Cannot run\
 unable to run tests as this user."
fi

