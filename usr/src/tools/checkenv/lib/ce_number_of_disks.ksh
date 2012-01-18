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
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Function ce_number_of_disks
#
# Check:  the number of disks on the system
#
# Args:
#	$1: minimum=x (the minimum number of disks required)
#		if no minimum then set value to 0
#	$2: maximum=y (the maximum number of disks required)
#		if no maximum then set value to 0
#
function ce_number_of_disks
{
	minimum=${1#minimum=}
	maximum=${2#maximum=}

	result_1=PASS	# check for minimum CPUs
	result_2=PASS	# check for maximum CPUs
	result=PASS	# overall result (result_1 + result_2)
	result_msg_1=
	result_msg_2=

        # Check the argument and make sure it is as expected - abort
	# otherwise.
	#
	errmsg="ce_number_of_disks expects 2 arguments (minimum=X and maximum=Y)"
	[[ $# -ne 2 ]] && abort $errmsg

	# Setup req_label and req_value.  There may be one or two
	# checks depending on the value of the args.  If the min and
	# max are the same than there is one check.  If the min !=
	# max there are two checks.

	# if minimum = maximum than that's the number of disks
	# required and there is really only one check.

	num_checks=1

	if [[ $minimum = $maximum ]] 
	then
		req_label_1="Number of disks required"
		req_value_1=$minimum

	else
	# there are 2 checks here

		num_checks=2
		req_label_1="Minimum number of disks"
		req_value_1=$minimum
		req_label_2="Maximum number of disks"
		req_value_2=$maximum
	fi

        # If operation is to dump info, dump and return
	[[ $OPERATION = "dump" ]] && {
		ce_number_of_disks_doc
		return $PASS
	}

	[[ $OPERATION = "verify" ]] && {

		typeset -i num_disks

		num_disks=$(ls -l /dev/rdsk/c*s2 | wc -l) 

		# Check 1

		if [[ $minimum -eq 0 || $num_disks -ge $minimum ]] 
		then
			result_1=PASS
		else
			result_1=FAIL
			result_msg_1="system has $num_disks disks (minimum of $minimum required)"
		fi

		# Check 2

		[[ $num_checks -eq 2 ]] && {
			if [[ $maximum -eq 0 || $num_disks -le $maximum ]] 
			then
				result_2=PASS
			else
				result_2=FAIL
				result_msg_2="system has $num_disks disks (maximum should be $maximum)"
			fi
		}
	}

	# Print out results - one line per check (either one or two)

	print_line $TASK "$req_label_1" "$req_value_1" "$result_1" \
		"$result_msg_1"
	[[ num_checks -eq 2 ]] &&  
		print_line $TASK "$req_label_2" "$req_value_2" "$result_2" \
			"$result_msg_2"

	# Since there are multiple results we have to figure out
	# what the overall result is
	#
	[[ $result_1 = "FAIL" || $result_2 = "FAIL" ]] && result=FAIL
	eval return \$$result
}

function ce_number_of_disks_doc 
{
	cat >&1 << EOF

Check ce_number_of_disks $(TASK)
=========================================
Description:
	Check if this system has a certain number of disks (either a
	specific number of a range). If the minimum does not equal the
	maximum there are two checks done - one for minimum and one for
	maximum.  Otherwise one check is done - the number of disks
	required
Arguments:
	#1 - minimum=<the minimum number of disks>, 0 if no min
	#2 - maximum=<the maximum number of disks>, 0 if no max
Requirement check (for this check):
	#1) $req_label_1
	#2) $req_label_2
Requirement value (for this check):
	#1) $req_value_1
	#2) $req_value_2
EOF
}
