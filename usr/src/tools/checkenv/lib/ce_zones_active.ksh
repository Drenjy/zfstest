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
# Function ce_zones_active
#
# Check to see if zones are active on the system.  This will also call
# ce_zones to verify that this system supports zones.
#
# Args:
#       $1: minimum=x (the minimum number of zones required)
#               if no minimum then set value to 0
#       $2: maximum=y (the maximum number of zones required)
#               if no maximum then set value to 0
#
function ce_zones_active
{
        minimum=${1#minimum=}
	maximum=${2#maximum=}
	result_1=PASS	# check for minimum zones
	result_2=PASS	# check for minimum zones
	result=PASS 	# overall result (result_1 + result_2)
	result_msg_1=
	result_msg_2=

	# Check the argument and make sure it is as expected - abort
	# otherwise.
	#
	errmsg="ce_zones_active expects 2 arguments (minimum=X and maximum=Y)"
	[ $# -ne 2 ] && abort $errmsg

	# Setup req_label and req_value.  There may be one or two
	# checks depending on the value of the args.  If the min and
	# max are the same than there is one check.  If the min !=
	# max there are two checks.

	num_checks=1
       	if [[ $minimum = $maximum ]]
	then
		req_label_1="Number of zones required"
		req_value_1=$minimum
	else
		# there are 2 checks here
		num_checks=2
		req_label_1="Minimum number of zones"
		req_value_1=$minimum
		req_label_2="Maximum number of zones"
		req_value_2=$maximum
	fi

	[[ $OPERATION = "dump" ]] && {
		ce_zones_active_doc
		return $PASS
	}

	[[ $OPERATION = "verify" ]] && {

	# 	First verify prerequistes
		(VERBOSE=; ce_zones supported)
		[[ $? -ne $PASS ]] && {
        		print_line $TASK "$req_label_1" "$req_value_1" "FAIL" "Prerequisite check ce_zones supported failed"
			[[ num_checks -eq 2 ]] &&
        			print_line $TASK "$req_label_2" "$req_value_2" "FAIL" "Prerequisite check, ce_zones supported, failed"
			return $FAIL
		}

		typeset -i num_zones
		num_zones=$(zoneadm info | grep -v global | wc -l)

		# Check 1:
		if [[ $num_zones -ge $minimum || $minimum -eq 0 ]]
		then
			result_1=PASS
			[[ $minimum -eq 0 ]] && result_msg_1="No minimum"
		else
			result_1=FAIL
			result_msg_1="system has $num_zones zones"
		fi

		# Check 2:
		[[ $num_checks -eq 2 ]] && {
			if [[ $num_zones -le $maximum || $maximum -eq 0 ]]
			then
				result_2=PASS
				[[ $maximum -eq 0 ]] && result_msg_2="No maximum"
			else
				result_2=FAIL
				result_msg_2="system has $num_zones zones"
			fi
		}
	}

        print_line $TASK "$req_label_1" "$req_value_1" "$result_1" \
		"$result_msg_1"
	[[ num_checks -eq 2 ]] && 
		print_line $TASK "$req_label_2" "$req_value_2" "$result_2" \
			"$result_msg_2"

	# Since there are multiple checks we need to figure out
	# the overall result

	[[ $result_1 -eq $FAIL || $result_2 -eq $FAIL ]] && result=FAIL
	eval return \$$result
}

function ce_zones_active_doc
{
	cat >&1 << EOF

Check ce_zones_active ($TASK)
================================
Description:
	This checks that the system has active zones.  As a side-effect it
	also calls ce_zones to verify that the system supports zones.
Arguments:
	#1 - minimum=<minimum number of zones>, 0 if no min
	#2 - maximum=<maximum number of zones>, 0 if no max
Requirement label (for this check):
	#1) $req_label_1
	#2) $req_label_2
Requirement value (for this check):
	#1) $req_value_1
	#2) $req_value_2
EOF
}
