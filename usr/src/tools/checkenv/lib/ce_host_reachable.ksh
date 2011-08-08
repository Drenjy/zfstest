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
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)ce_host_reachable.ksh	1.5	09/03/29 SMI"
#

#
# Function check_reachability
#
# Args: <void>
#
# Purpose:
#	To check whether the host specified in variable $host
#	is reachable by the method defined by variable $how
#
# Returns:
#	0, if host is reachable, sets result to PASS.
#	1, otherwise, sets result to FAIL, also sets variable $errmsg
#
function check_reachability
{
	case $how in
	ping)
		/usr/sbin/ping -A $ip_version $host >/dev/null 2>&1
		if (($? != 0)); then
			errmsg="host $host is unreachable via $ip_version ping"
			result=FAIL
		else
			result=PASS
		fi
		;;
	rsh)
		/bin/rsh -n $host /bin/hostname >/dev/null 2>&1
		if (($? != 0)); then
			result=FAIL
			errmsg="host $host is rsh unreachable!\n
\t*** INSTRUCTIONS TO ENABLE rsh ON $host:
\t*** 1. svcadm enable svc:/network/shell:default
\t*** 2. echo '+ +' > ~root/.rhosts"
		else
			result=PASS
		fi
		;;
	rlogin)
		rlogin_svc=$(/bin/rsh -n $host \
			"/bin/svcprop -p restarter/state rlogin 2>/dev/null")
		if [[ $rlogin_svc != online ]]; then
			result=FAIL
			errmsg="host $host is rlogin unreachable!\n
\t*** INSTRUCTIONS TO ENABLE rlogin ON $host:
\t*** 1. svcadm enable svc:/network/shell:default
\t*** 2. svcadm enable svc:/network/login:rlogin
\t*** 3. echo '+ +' > ~root/.rhosts
\t*** 4. Edit /etc/default/login to allow root login on non-console ttys"
		else
			result=PASS
		fi
		;;
	ssh)
		/bin/ssh $host /bin/hostname >/dev/null 2>&1
		if (($? != 0)); then
			result=FAIL
			errmsg="host $host is ssh unreachable\n"
		else
			result=PASS
		fi
		;;
	*)
		result=FAIL
		errmsg="Illegal reachability operation: $how"
		;;
	esac

	eval return \$$result
}

#
# Function ce_host_reachable
#
# This function checks whether the host is reachable
# Calls check_reachability to perform the actual reachability check(s).
#
# Args:
#	$1 - host name
#	$2 - connectivity method: "ping" (default), "rsh", "rlogin" or "ssh" 
#	$3 - "inet" (default) or "inet6": valid only if $2 == ping
#
function ce_host_reachable
{
	errmsg="usage: ce_host_reachable <host> [rsh|rlogin|ssh|ping [inet|inet6]]"

	host=$1
	how=ping
	ip_version=inet

	case $# in
	1) ;;
	2)
		valid=0
		for method in ping rsh rlogin ssh; do
			[[ $2 == $method ]] && valid=1 && break
		done
		((valid == 0)) && abort $errmsg
		how=$method
		;;
	3)
		if [[ $2 != ping ]] || [[ $3 != inet ]] && [[ $3 != inet6 ]];
		then
			abort $errmsg
		fi
		ip_version=$3
		;;
	*)      abort $errmsg
		;;
	esac

	req_label="the host is reachable or not"
	req_value="$host"
	result=FAIL

	if [ $OPERATION == "dump" ]; then
		ce_host_reachable_doc
		result=PASS
	fi

	if [ $OPERATION == "verify" ]; then
		errmsg="$req_value is unreachable"
		check_reachability
		[[ $? -eq 0 ]] && errmsg="" && result=PASS
	fi

	print_line $TASK "$req_label" "$req_value" "$result" "$errmsg"
	eval return \$$result
}

function ce_host_reachable_doc
{
	cat >&1 << EOF

Check ce_host_reachable
=================================
Description:
	check whether the host is reachable
Arguments:
	#1 - host name
	#2 - connectivity method: "ping" (default), "rsh", "rlogin" or "ssh"
	#3 - "inet" (default) or "inet6": valid only if $2 == ping
Requirement label (for this check):
	$req_label
Requirement value (for this check):
	$req_value
EOF
}
