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
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Copyright (c) 2012 by Delphix. All rights reserved.
#

. $STF_SUITE/tests/functional/cli_user/zfs_list/zfs_list.kshlib

#
# DESCRIPTION:
#	Verify 'zfs list' evaluate multiple '-s' options from left to right
#	in decreasing order of importance.
#
# STRATEGY:
#	1. Setting user property f:color for filesystem and volume.
#	2. Setting user property f:amount for filesystem and volume.
#	3. Setting reservation for filesystem and volume
#	3. Verify 'zfs list' evaluated multiple -s options from left to right.
#

verify_runnable "both"

log_assert "Verify 'zfs list' evaluate multiple '-s' options " \
	"from left to right in decreasing order of importance."

COLOR="red yellow green blue red yellow white"
AMOUNT="0217 812 0217 0781 7 1364 687"
RESERVATION="2048K 1024 2048K 512K 16M 3072 128K"

basefs=$TESTPOOL/$TESTFS
typeset -i n=0
for ds in $DATASETS; do
	color=$($ECHO $COLOR | $AWK '{print $1}')
	log_must $ZFS set f:color=$color $basefs/$ds
	if is_global_zone; then
		log_must $ZFS set f:color=$color $basefs/${ds}-vol
	fi
	eval COLOR=\${COLOR#$color }

	amount=$($ECHO $AMOUNT | $AWK '{print $1}')
	log_must $ZFS set f:amount=$amount $basefs/$ds
	if is_global_zone; then
		log_must $ZFS set f:amount=$amount $basefs/${ds}-vol
	fi
	eval AMOUNT=\${AMOUNT#$amount }

	reserv=$($ECHO $RESERVATION | $AWK '{print $1}')
	log_must $ZFS set reservation=$reserv $basefs/$ds
	if is_global_zone; then
		log_must $ZFS set reservation=$reserv $basefs/${ds}-vol
	fi
	eval RESERVATION=\${RESERVATION#$reserv }
done

#
# we must be in the C locale here, as running in other locales
# will make zfs use that locale's sort order.
#
LC_ALL=C; export LC_ALL

fs_color_amount="Orange Carrot Apple apple carrot banana Banana"
fs_amount_color="Carrot Apple Orange banana carrot apple Banana"
fs_color_reserv="Orange Carrot Apple apple carrot Banana banana"
fs_reserv_color="Banana banana carrot Orange Carrot Apple apple"
fs_reserv_amount_color="Banana banana carrot Orange Carrot Apple apple"

vol_color_amount="Orange-vol Carrot-vol Apple-vol apple-vol carrot-vol"
vol_color_amount="$vol_color_amount banana-vol Banana-vol"

vol_amount_color="Carrot-vol Apple-vol Orange-vol banana-vol carrot-vol"
vol_amount_color="$vol_amount_color apple-vol Banana-vol"

vol_color_reserv="Orange-vol Carrot-vol Apple-vol apple-vol carrot-vol"
vol_color_reserv="$vol_color_reserv Banana-vol banana-vol"

vol_reserv_color="Banana-vol banana-vol carrot-vol Orange-vol Carrot-vol"
vol_reserv_color="$vol_reserv_color Apple-vol apple-vol"

vol_reserv_amount_color="Banana-vol banana-vol carrot-vol Orange-vol Carrot-vol"
vol_reserv_amount_color="$vol_reserv_amount_color Apple-vol apple-vol"

if is_global_zone; then
	#snap list for color_amount
	snap_list1="Orange@snap Orange-vol@snap Carrot@snap Carrot-vol@snap"
	snap_list1="$snap_list1 Apple@snap Apple-vol@snap apple@snap apple-vol@snap"
	snap_list1="$snap_list1 carrot@snap carrot-vol@snap banana@snap banana-vol@snap"
	snap_list1="$snap_list1 Banana@snap Banana-vol@snap"

	#snap list for amount_color
	snap_list2="Carrot@snap Carrot-vol@snap Apple@snap Apple-vol@snap"
	snap_list2="$snap_list2 Orange@snap Orange-vol@snap banana@snap banana-vol@snap"
	snap_list2="$snap_list2 carrot@snap carrot-vol@snap apple@snap apple-vol@snap"
	snap_list2="$snap_list2 Banana@snap Banana-vol@snap"

	#snap list for color_reserv
	snap_list3="Orange@snap Orange-vol@snap Carrot@snap Carrot-vol@snap"
	snap_list3="$snap_list3 Apple@snap Apple-vol@snap apple@snap apple-vol@snap"
	snap_list3="$snap_list3 carrot@snap carrot-vol@snap Banana@snap Banana-vol@snap"
	snap_list3="$snap_list3 banana@snap banana-vol@snap"

else
	snap_list1="Orange@snap Carrot@snap Apple@snap apple@snap"
	snap_list1="$snap_list1 carrot@snap banana@snap Banana@snap"

	snap_list2="Carrot@snap Apple@snap Orange@snap banana@snap"
	snap_list2="$snap_list2 carrot@snap apple@snap Banana@snap"

	snap_list3="Orange@snap Carrot@snap Apple@snap apple@snap"
	snap_list3="$snap_list3 carrot@snap Banana@snap banana@snap"

fi
# Sort by color,amount
verify_sort \
    "$ZFS list -H -r -o name -s f:color -s f:amount -t filesystem $basefs" \
    "$fs_color_amount" "f:color,f:amount"
if is_global_zone; then
	verify_sort \
	    "$ZFS list -H -r -o name -s f:color -s f:amount -t volume $basefs" \
	    "$vol_color_amount" "f:color,f:amount"
fi
# Sort by amount,color
verify_sort \
    "$ZFS list -H -r -o name -s f:amount -s f:color -t filesystem $basefs" \
    "$fs_amount_color" "f:amount,f:color"
if is_global_zone; then
	verify_sort \
	    "$ZFS list -H -r -o name -s f:amount -s f:color -t volume $basefs" \
	    "$vol_amount_color" "f:amount,f:color"
fi

# Sort by color reservation
verify_sort \
    "$ZFS list -H -r -o name -s f:color -s reserv -t filesystem $basefs" \
    "$fs_color_reserv" "f:color,reserv"
if is_global_zone; then
	verify_sort \
	    "$ZFS list -H -r -o name -s f:color -s reserv -t volume $basefs" \
	    "$vol_color_reserv" "f:color,reserv"
fi
# Sort by reserv, color
verify_sort \
    "$ZFS list -H -r -o name -s reserv -s f:color -t filesystem $basefs" \
    "$fs_reserv_color" "reserv,f:color"
if is_global_zone; then
	verify_sort \
	    "$ZFS list -H -r -o name -s reserv -s f:color -t volume $basefs" \
	    "$vol_reserv_color" "reserv,f:color"
fi

# Sort by reservation, amount, color
verify_sort \
    "$ZFS list -H -r -o name -s reserv -s reserv -s f:amount -s f:color -t filesystem $basefs" \
    "$fs_reserv_amount_color" "reserv,:amount,f:color"
if is_global_zone; then
	verify_sort \
	    "$ZFS list -H -r -o name -s reserv -s f:amount -s f:color -t volume $basefs" \
	    "$vol_reserv_amount_color" "reserv,:amount,f:color"
fi
# User property and reservation was not stored in snapshot
verify_sort \
    "$ZFS list -H -r -o name -s f:color -s f:amount -t snapshot $basefs" \
    "$snap_list1" "f:color,f:amount"
verify_sort \
    "$ZFS list -H -r -o name -s f:amount -s f:color -t snapshot $basefs" \
    "$snap_list2" "f:amount,f:color"
verify_sort \
    "$ZFS list -H -r -o name -s f:color -s reserv -t snapshot $basefs" \
    "$snap_list3" "f:color,reserv"
verify_sort \
    "$ZFS list -H -r -o name -s reserv -s f:color -t snapshot $basefs" \
    "$snap_list3" "reserv,f:color"
verify_sort \
    "$ZFS list -H -r -o name -s reserv -s f:amount -s f:color -t snapshot $basefs" \
    "$snap_list2" "reserv,f:amount,f:color"

log_pass "Verify 'zfs list' evaluate multiple '-s' options " \
	"from left to right in decreasing order of importance."
