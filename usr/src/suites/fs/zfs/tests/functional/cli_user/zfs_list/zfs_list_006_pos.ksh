#!/bin/ksh -p
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
. $STF_SUITE/tests/functional/cli_user/zfs_list/zfs_list.kshlib

#################################################################################
#
# __stc_assertion_start
#
# ID: zfs_list_006_pos
#
# DESCRIPTION:
#	Verify 'zfs list' exclude list of snapshot.
#
# STRATEGY:
#	1. Verify snapshot not shown in the list:
#		zfs list [-r]
#	2. Verify snapshot will be shown by following case:
#		zfs list [-r] -t snapshot
#		zfs list [-r] -t all
#		zfs list <snapshot>
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING_STATUS: COMPLETED (2009-04-24)
#
# __stc_assertion_end
#
################################################################################

verify_runnable "both"

if ! pool_prop_exist "listsnapshots" ; then
	log_unsupported "Pool property of 'listsnapshots' not supported."
fi

function cleanup
{
	if [[ -n $oldvalue ]] && is_global_zone ; then
		log_must $ZPOOL set listsnapshots=$oldvalue $pool
	fi
}

log_onexit cleanup
log_assert "Verify 'zfs list' exclude list of snapshot."

set -A hide_options "--" "-t filesystem" "-t volume"
set -A show_options "--" "-t snapshot" "-t all"

typeset pool=${TESTPOOL%%/*}
typeset oldvalue=$(get_pool_prop listsnapshots $pool)
typeset	dataset=${DATASETS%% *}
typeset BASEFS=$TESTPOOL/$TESTFS

for newvalue in "" "on" "off" ; do

	if [[ -n $newvalue ]] && ! is_global_zone ; then
		break
	fi

	if [[ -n $newvalue ]] ; then
		log_must $ZPOOL set listsnapshots=$newvalue $pool
	fi

	typeset expect="log_must"

	if [[ -z $newvalue ]] &&  check_version "5.11" ; then
		expect="log_mustnot"
	elif [[ $newvalue == "off" ]] ; then
		expect="log_mustnot"
	fi
	
	$expect eval "$ZFS list -r -H -o name $pool | $GREP '@' > /dev/null 2>&1"
		
	typeset -i i=0
	while (( i < ${#hide_options[*]} )) ; do
		log_mustnot eval "$ZFS list -r -H -o name ${hide_options[i]} $pool | \
$GREP '@' > /dev/null 2>&1"

		(( i = i + 1 ))
	done

	(( i = 0 ))

	while (( i < ${#show_options[*]} )) ; do
		log_must eval "$ZFS list -r -H -o name ${show_options[i]} $pool | \
$GREP '@' > /dev/null 2>&1"
	
		(( i = i + 1 ))
	done

	output=$($ZFS list -H -o name $BASEFS/${dataset}@snap)
	if [[ $output != $BASEFS/${dataset}@snap ]] ; then
		log_fail "zfs list not show $BASEFS/${dataset}@snap"
	fi
	
	if is_global_zone ; then
		output=$($ZFS list -H -o name $BASEFS/${dataset}-vol@snap)
		if [[ $output != $BASEFS/${dataset}-vol@snap ]] ; then
			log_fail "zfs list not show $BASEFS/${dataset}-vol@snap"
		fi
	fi
done
	
log_pass "'zfs list' exclude list of snapshot."
