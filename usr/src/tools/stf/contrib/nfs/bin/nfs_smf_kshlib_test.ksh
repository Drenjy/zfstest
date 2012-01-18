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

# The caller needs root permission to run the script.
. ${STF_TOOLS}/contrib/include/nfs-smf.kshlib
. ${STF_TOOLS}/contrib/include/libsmf.shlib

timeout=60
i=1
while (( i<10 )); do
	((i=i+1))
	nfs_smf_setup rw /tmp $timeout
	if [[ $? == 0  ]];then
		echo "test setup function successfully"
		echo "PASS $i"
	else
		echo "test failed"
		exit
	fi
	nfs_smf_clean /tmp $timeout
	if [[ $? == 0  ]];then
		echo "test clean function successfully"
		echo "PASS $i"
	else
		echo "test failed"
		exit
	fi
done
