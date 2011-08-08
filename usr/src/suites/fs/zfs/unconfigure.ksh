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
# ident	"@(#)unconfigure.ksh	1.3	07/05/25 SMI"
#

. ${STF_SUITE}/include/libtest.kshlib
. ${STF_SUITE}/default.cfg
. ${STF_SUITE}/commands.cfg

set -A rhosts $RHOSTS

if check_iscsi_remote ; then
	iscsi_iclose $rhosts[0]
fi

if (( ${#RHOSTS} != 0 )) && (( ${#RDISKS} != 0 )); then
	for rhost in $RHOSTS; do
		rsh_status "" $rhost "$RM -rf $RTEST_ROOT"
		(( $? != 0 )) && \
			log_fail "Remove directory in remote host - $rhost failed."
	done
	
fi

if [ ! -z "$zone_name" ]
then
   echo y | $ZONEADM -z $zone_name halt
   echo y | $ZONEADM -z $zone_name uninstall -F
   echo y | $ZONECFG -z $zone_name delete -F
fi

log_pass 
