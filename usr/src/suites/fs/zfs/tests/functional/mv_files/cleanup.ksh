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
# ident	"@(#)cleanup.ksh	1.2	07/01/09 SMI"
#

. $STF_SUITE/include/libtest.kshlib

verify_runnable "global"
verify_runtime $RT_MEDIUM

[[ -f /var/tmp/exitsZero.ksh ]] && \
	log_must $RM -f /var/tmp/exitsZero.ksh
[[ -f /var/tmp/testbackgprocs.ksh ]] && \
	log_must $RM -f /var/tmp/testbackgprocs.ksh

ismounted $TESTPOOL/$TESTFS_TGT
(( $? == 0 )) && log_must $ZFS umount $TESTPOOL/$TESTFS_TGT 
log_must $ZFS destroy $TESTPOOL/$TESTFS_TGT

if [[ -d $TESTDIR_TGT ]]; then
	log_must $RM -rf $TESTDIR_TGT
fi

default_cleanup
