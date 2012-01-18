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

#
# The script is to create pool with vdevs specified, then make two volumes
# as iSCSI targets
# $1 specified vdevs, if $1 is "detect", then all available disks are used
# Return 0 if the script succeeds, otherwise return 1
#

# Prepare the environment first, such as getting the value of
# $STF_TOOLS and $STF_SUITE

. ${STF_SUITE}/default.cfg
. ${STF_SUITE}/include/libtest.kshlib
. ${STF_SUITE}/tests/functional/remote/remote_common.kshlib

typeset STF_TOOLS_PKG="SUNWstc-stf"
typeset STF_SUITE_PKG=$(get_package_name)
typeset STF_TOOLS_DIR
typeset STF_SUITE_DIR

typeset CUR_PROG=$(whence $0)
typeset CUR_DIR=$(dirname $CUR_PROG)

. ${CUR_DIR}/libremote.kshlib

if pkg_isinstalled $STF_TOOLS_PKG ; then
	STF_TOOLS_DIR=$(pkg_getinstbase $STF_TOOLS_PKG)
	export STF_TOOLS=$STF_TOOLS_DIR
fi

if pkg_isinstalled $STF_SUITE_PKG ; then
	STF_SUITE_DIR=$(pkg_getinstbase $STF_SUITE_PKG)
	export STF_SUITE=$STF_SUITE_DIR
fi

if [[ -z $STF_TOOLS ]] ; then
	print -u2 "Package $STF_TOOLS_PKG is not installed."
	exit 1
fi

if [[ -z $STF_SUITE ]]; then
	print -u2 "Package $STF_SUITE_PKG is not installed."
	exit 1
fi

# Environment preparation ends here

typeset ISCSIT_FMRI="svc:/system/iscsitgt:default"
typeset TPOOL="tpool$$"
typeset TVOL1="vol1"
typeset TVOL2="vol2"
typeset -i SIZE12G=$(( 1024 * 1024 * 1024 * 12 ))
typeset -i TVOLSIZE=$(( 1024 * 1024 * 1024 * 5 )) # default is 5G

# get available disks used for iscsi targets on remote machine first
if [[ $1 == "detect" ]]; then
	TDISKS=$(find_disks)
else
	TDISKS=$(find_disks $1)
fi

for disk in ${TDISKS}; do
        $ZPOOL create -f foo_pool$$ $disk > /dev/null 2>&1
        # if disk is found not usable to create a pool, exclude it from $TDISKS
        if (( $? == 0 )); then
                $ECHO $TDISKS | $GREP $disk > /dev/null 2>&1
                if (( $? == 0 )) ; then
			gooddisks="$disk $gooddisks"
		fi
                $ZPOOL destroy -f foo_pool$$
        fi
done

if (( ${#gooddisks} == 0 )) ; then
	log_fail "No good disks for test."
fi
TDISKS="$gooddisks"

# check svc:/system/iscsitgt:default state, try to enable it if the state
# is not ON
if [[ "ON" != $($SVCS -H -o sta $ISCSIT_FMRI) ]]; then
	log_must $SVCADM enable $ISCSIT_FMRI

	typeset -i retry=20
	while [[ "ON" != $($SVCS -H -o sta $ISCSIT_FMRI) && ( $retry -ne 0 ) ]]
	do
		(( retry = retry - 1 ))
		$SLEEP 1
	done

	if [[ "ON" != $($SVCS -H -o sta $ISCSIT_FMRI) ]]; then
		log_fail "$ISCSIT_FMRI service can not be enabled!"
	fi

fi

log_must $ZPOOL create -f $TPOOL $TDISKS
TPOOL_SIZE=$(get_prop avail $TPOOL)

if [[ $TPOOL_SIZE -lt $SIZE12G ]]; then
	(( TPOOL_SIZE = TPOOL_SIZE - TPOOL_SIZE / 5 ))
	(( TVOLSIZE = TPOOL_SIZE / 2 ))
fi

log_must $ZFS set shareiscsi=on $TPOOL
log_must $ZFS create -V $TVOLSIZE $TPOOL/$TVOL1
log_must $ZFS create -V $TVOLSIZE $TPOOL/$TVOL2

# Verify targets is created
log_must is_iscsi_target $TPOOL/$TVOL1
log_must is_iscsi_target $TPOOL/$TVOL2

log_pass "Targets setup is complete."
