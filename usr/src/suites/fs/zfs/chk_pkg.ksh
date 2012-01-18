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
. ${STF_SUITE}/include/libtest.kshlib

#
# This script is used to check whether the test suites package
# with target version is installed or not in a remote machine.  
# There is one argument:
# $1, the target package version 
#

pkgver="$1"
pkgname=$(get_package_name)
rhost=`/usr/bin/uname -n`

function pkg_match #<pkg version>
{
	typeset tgt_ver=$1
	typeset cur_ver=""
	typeset pkginfo_file=/tmp/pkginfo.$$

	/usr/bin/pkginfo -l $pkgname >$pkginfo_file
	cur_ver=`/usr/bin/cat $pkginfo_file | /usr/bin/grep "VERSION:" \
		| /usr/bin/awk '{print $2}' | /usr/bin/cut -d, -f1,2`

	if [[ "$cur_ver" != "$tgt_ver" ]]; then
		return 1
	else
		return 0
	fi
}

/usr/bin/pkginfo -q $pkgname
if (( $? !=0 )); then
	print -u2 "Warning: the $pkgname is not installed" \
		"in remote host -- $rhost."	
	exit 1
fi

if ! pkg_match $pkgver; then 
	print -u2 "Warning: the $pkgname in remote host -- $rhost" \
		"has different version."
	exit 1
fi

exit 0
