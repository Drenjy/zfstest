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

. $STF_SUITE/include/libtest.kshlib

#
# DESCRIPTION:
#
# Pool properties can be read but can't be set within a zone
#
# STRATEGY:
# 1. Verify we can read pool properties in a zone
# 2. Verify we can't set a pool property in a zone
#

verify_runnable "local"

log_assert "Pool properties can be read but can't be set within a zone"

log_must $ZPOOL get all zonepool
log_must $ZPOOL get bootfs zonepool
log_mustnot $ZPOOL set boofs=zonepool zonepool

# verify that the property hasn't been set.
log_must eval "$ZPOOL get bootfs zonepool > /tmp/output.$$"
log_must $GREP "zonepool  bootfs    -" /tmp/output.$$

$RM /tmp/output.$$

log_pass "Pool properties can be read but can't be set within a zone"
