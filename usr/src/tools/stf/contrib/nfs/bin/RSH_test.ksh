#! /usr/bin/ksh -p
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

#
# The system must be able to 'rsh' to server as root.
#
if [[ $# != 1 ]]; then
	echo "Usage: ./`basename $0` <SERVER>"
	exit 1
fi

. ${STF_TOOLS}/contrib/include/nfs-util.kshlib

TMPDIR=/usr/tmp

RSH root $1 "date" >/dev/null 2>&1
if [[ $? == 0  ]]; then
	echo "test RSH function successfully"
else
	echo "test failed"
	exit
fi
