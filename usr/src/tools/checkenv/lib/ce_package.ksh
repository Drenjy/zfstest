#! /usr/bin/ksh  -p
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
# ident	"@(#)ce_package.ksh	1.4	09/03/29 SMI"
#

#
# Function ce_package
#
# This function checks if a package exists on the system.
#
# Args:
#	$1: package, the name of the package which should exist on the system
#	$2: host, the name of the host on which the package should exist,
#	    system under testing as default
#
function ce_package
{
	pkg=${1}
	host=${2}

	result=FAIL

	# Check the argument and make sure it is as expected - abort otherwise.
	errmsg="usage: ce_package <package> [host]"
	[[ $# -gt 2  ]] || [[ $# -lt 1 ]] && abort $errmsg

	# Set req values
	req_label="Required package"
	req_value="$pkg"

	# If operation is to dump info, dump and return
	[[ $OPERATION = "dump" ]] && {
		ce_package_doc
		result=PASS
	}

	#
	# Verify that the system meets requirements - set result=[PASS|FAIL]
	#
	[[ $OPERATION = "verify" ]] && {
		if [[ -z $host ]]; then
			pkginfo -q $pkg >/dev/null 2>&1
			if [[ $? -eq 0 ]]; then
				errmsg=""; result=PASS
			else
				result=FAIL
				errmsg="Package $pkg not found"
			fi
		else
			ce_host_reachable $host rsh
			if (($? != 0)); then
				abort "host $host is rsh unreachable"
			fi
			pkginfo=$(rsh -n $host "pkginfo $pkg" 2>/dev/null)
			if [[ -n $pkginfo ]]; then
				errmsg=""; result=PASS
			else
				result=FAIL
				errmsg="Package $pkg not found on host $host"
			fi
		fi
	}

	print_line $TASK "$req_label" "$req_value" "$result" "$errmsg"
	eval return \$$result
}

function ce_package_doc
{
	cat >&1 << EOF

Check ce_package ($TASK)
=========================
Description:
	Check if a package is installed on the system
Arguments:
	#1 - package name
	#2 - host name, system under testing as default
Requirement label (for this check):
	$req_label
Requirement value (for this check):
	$req_value
EOF
}
