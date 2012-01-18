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

# max and min pool version
typeset -i MAX_POOL_VERSION=$($ZPOOL upgrade|$HEAD -1|$AWK '{print $NF}'|$SED -e   's/\.//g')
typeset -i MIN_POOL_VERSION=10

# max and min file system version
typeset -i MAX_FS_VERSION=$($ZFS upgrade|$HEAD -1|$AWK '{print $NF}'|$SED -e   's/\.//g')
typeset -i MIN_FS_VERSION=2

. ${STF_SUITE}/include/libtest.kshlib

typeset PKGNAME=$(get_package_name)

function usage
{
        log_fail "Usage: $0 -c \"DISKS=<disks>\" \n" \
			"[-c \"RUNTIME={short|medium|long}" \
                        "[-c \"KEEP=<pools>\"] \n"\
                        "[-c \"zone={new|existing}\"] \n"\
                        "[-c \"zone_name=<zone_name>\"] \n" \
                        "[-c \"zone_root=<zone_root\"] \n" \
                        "[-c \"zone_ip=<zone_ip>\"] \n" \
                        "[-c \"RHOSTS=<remote hosts>\"] \n"\
                        "[-c \"ZPOOL_TEST_VERSION=<zpool test version>\"] \n"\
                        "[-c \"ZFS_TEST_VERSION=<zfs test version>\"] \n"\
                        "[-c \"RDISKS=<disks for each host in RHOSTS>\"]" \
                        "\n\nwhere:\n"\
                        "the order to assign disks should be the same as \n"\
                        "that in RHOSTS. You can assign a 'detect' to seek\n" \
                        " any available disks in a remote host. If you \n" \
                        " assign more than one disk from command line \n"\
                        " for a host, you\n"\
                        " need to use '' to quote all the disks as a unit.\n" \
                        "[-c \"RTEST_ROOT=<directory in remote host>\"]" \
                        "[-c \"WRAPPER=<wrapper name list>\"]"
}

configfile=$1
shift

if [[ -n $RUNTIME ]]; then
	RUNTIME=`echo $RUNTIME | tr "[:upper:]" "[:lower:]"`
	case $RUNTIME in
		long) RUNTIME=$RT_LONG
			;;
		medium) RUNTIME=$RT_MEDIUM
			;;
		short) RUNTIME=$RT_SHORT
			;;
		*) log_fail "'$RUNTIME' must be {long, medium, short}"
			;;
	esac
else
	# We default to 'long' mode for backward compatibilty.
	RUNTIME=$RT_LONG
fi

log_note "--- Begin Test Suite Parameters:"
log_note "      DISKS=\"$DISKS\""
log_note "      KEEP=\"$KEEP\""
log_note "      RUNTIME=\"$RUNTIME\""
log_note "      zone=\"$zone\""
log_note "      zone_name=\"$zone_name\""
log_note "      zone_root=\"$zone_root\""
log_note "      zone_ip=\"$zone_ip\""
log_note "      RHOSTS=\"$RHOSTS\""
log_note "      RDISKS=\"$RDISKS\""
log_note "      RTEST_ROOT=\"$RTEST_ROOT\""
log_note "      ZPOOL_TEST_VERSION=\"$ZPOOL_TEST_VERSION\""
log_note "      ZFS_TEST_VERSION=\"$ZFS_TEST_VERSION\""
log_note "      iscsi=\"$iscsi\""
log_note "      WRAPPER=\"$WRAPPER\""
log_note "--- End Test Suite Parameters"

if (( ZPOOL_TEST_VERSION != 0 )); then
	if (( ZPOOL_TEST_VERSION > MAX_POOL_VERSION )) ||
		(( ZPOOL_TEST_VERSION < MIN_POOL_VERSION )) ; then
		log_fail "Invalid pool version: $ZPOOL_TEST_VERSION. [$MIN_POOL_VERSION - $MAX_POOL_VERSION]"
	fi
fi

if (( ZFS_TEST_VERSION != 0 )); then
	$ZPOOL create 2>&1|$GREP "\-O" >/dev/null 2>&1
	if [[ $? != 0 ]]; then
		log_fail "zpool create -O can't be supported, so can't set ZFS_TEST_VERSION."
	fi
	if (( ZFS_TEST_VERSION > MAX_FS_VERSION )) ||
		(( ZFS_TEST_VERSION < MIN_FS_VERSION )) ; then
		log_fail "Invalid fs version: $ZFS_TEST_VERSION. [$MIN_FS_VERSION - $MAX_FS_VERSION]"
	fi
fi

#
# Verify the wrapper is exist and runnable.
#
typeset ZPOOL_WRAPPER
typeset ZFS_WRAPPER
for wrapper in $WRAPPER ; do
	if [[ -x ${STF_SUITE}/bin/zpool_$wrapper ]]; then
		ZPOOL_WRAPPER="${ZPOOL_WRAPPER} $wrapper"
	fi
	if [[ -x ${STF_SUITE}/bin/zfs_$wrapper ]]; then
		ZFS_WRAPPER="${ZFS_WRAPPER} $wrapper"
	fi
done

if [[ "$ZPOOL_TEST_VERSION" != "0" ]] ||
	[[ "$ZFS_TEST_VERSION" != "0" ]]; then
        if [[ -x ${STF_SUITE}/bin/zpool_version ]]; then
                ZPOOL_WRAPPER="${ZPOOL_WRAPPER} version"
        fi
fi

if [[ "$ZFS_TEST_VERSION" != "0" ]]; then
        if [[ -x ${STF_SUITE}/bin/zfs_version ]]; then
                ZFS_WRAPPER="${ZFS_WRAPPER} version"
        fi
fi

if [[ -n ${ZPOOL_WRAPPER} ]]; then
	export ZPOOL=zpool
	export ZPOOL_WRAPPER
fi

if [[ -n ${ZFS_WRAPPER} ]]; then
	export ZFS=zfs
	export ZFS_WRAPPER
fi


# Make sure that all commands are executable.

for cmd in $CMDS ; do
        [[ -x $cmd ]] || log_fail "$cmd must exist and be executable"
done
if ! is_global_zone; then
	#
	# Remove any existing ZFS data sets, so system is in known state
	# before starting tests.
	#
	default_cleanup_noexit

	cat >> $configfile <<-EOF
	export RUNTIME="$RUNTIME"
	export ZPOOL_WRAPPER="${ZPOOL_WRAPPER}"
	export ZFS_WRAPPER="${ZFS_WRAPPER}"
	export ZPOOL="${ZPOOL}"
	export ZFS="${ZFS}"
	export ZPOOL_TEST_VERSION="${ZPOOL_TEST_VERSION}"
	export ZFS_TEST_VERSION="${ZFS_TEST_VERSION}"
	EOF

	log_pass
fi

#
# Verify ZFS is installed on this machine
# The test suite cannot execute without ZFS being installed.
#
if [[ $(isainfo -b) -eq 32 && -x /kernel/drv/zfs ]] || 
	[[ -x /kernel/drv/$(isainfo -k)/zfs ]]; then
	log_note "ZFS is installed on this machine."
else
	log_fail "ZFS is not installed on this machine. Aborting."
fi

# Set the ROOTPOOL and ROOTFS environment variables
$DF -n / | $GREP zfs > /dev/null
if [ $? -eq 0 ]
then
	ROOTPOOL=$($DF -h / | $TAIL -1 | $AWK -F/ '{print $1}')
	ROOTFS=$($DF -h / | $TAIL -1 | $AWK '{print $1}')
fi
export ROOTPOOL="$ROOTPOOL"
export ROOTFS="$ROOTFS"

DUMP_DEV=$($DUMPADM | $GREP "Dump device" | $AWK '{print $3}')
if [[ $DUMP_DEV == "none" ]]; then
	log_fail "Dump device is 'none', please set it."
fi

#
# We must always preserve $ROOTPOOL
#
KEEP="^$ROOTPOOL $KEEP"

#
# Verify the list of disks is valid
#
for each_item in $DISKS $KEEP
do
        $ECHO "$each_item" | $EGREP "[,;]" > /dev/null
        RET=$?
        if (( $RET == 0 )); then
                log_fail "List parameters must be space separated."
        fi
done

#
# Verify DISKS are not disk slices
#
for each_item in $DISKS
do
        $ECHO "$each_item" | $EGREP "[ps][0-9]$" > /dev/null
        RET=$?
        if (( $RET == 0 )); then
                log_fail "Disk slices should be not passed in as parameters."
        fi
done

COUNT=`$ECHO $DISKS | $WC -w`
if (( $COUNT < 1 )) ; then
        log_fail "A minimum of one disks is required to run."
fi

if [[ -n $KEEP ]]; then

	#
	# Replace "word" with "^word$|" which will create a
	# regular expression for 'egrep'.
	#
	# e.g. we need to avoid 'pool' also excluding 'testpool'
	# given that 'pool' is a substring of 'testpool'.
	#	
	KEEP=`$ECHO $KEEP | $SED "s/ /$|^/g"`
	KEEP="${KEEP}$" # Append an end-of-line delimiter.
else
	KEEP="^${ROOTPOOL}$" # Append an end-of-line delimiter.
fi

remote_ready="off" #flag to see RHOSTS and RDISKS are set correctly
if (( ${#RHOSTS} != 0 )) && (( ${#RDISKS} != 0 )); then
        eval set -A rhosts $RHOSTS
        eval set -A rdisks $RDISKS
        if (( ${#rhosts[*]} != ${#rdisks[*]} )); then
                log_fail "Some remote hosts may not be assigned disks, please check."
        fi

        typeset -i i=0
        while (( i < ${#rhosts[*]} )); do
                ! verify_rsh_connect ${rhosts[i]} && \
                        log_fail "rsh connection to $rhost verification failed."
                (( i = i + 1 ))
        done

	#Get the ZFS test suites package version info in local machine
	pkgver=`$PKGINFO -l $PKGNAME | $GREP "VERSION:" | \
		$AWK '{print $2}' | $CUT -d, -f1,2`
	
        i=0
        while (( i < ${#rhosts[*]} )); do
		cp_files="${STF_SUITE}/chk_pkg \
			${STF_SUITE}/include/libremote.kshlib \
			${STF_SUITE}/iscsi_tsetup \
			${STF_CONFIG}/stf_config.vars"
                rsh_status ""  ${rhosts[i]} "$RM -rf $RTEST_ROOT;\
			$MKDIR -p -m 0777 $RTEST_ROOT"
		(( $? != 0 )) && \
			log_fail "Create directory in remote host failed."
		for file in $cp_files; do
			$RCP $file ${rhosts[i]}:$RTEST_ROOT > /dev/null 2>&1
			(( $? !=0 )) && \
				log_fail "Copying files to ${rhosts[i]} failed."
		done

		rsh_status "" ${rhosts[i]} "$CHMOD a+x $RTEST_ROOT/chk_pkg; \
			$RTEST_ROOT/chk_pkg $pkgver"	
		(( $? != 0 )) && log_fail "zfs test version on local and \
			remote do not match."

		(( i = i + 1 ))
        done
	# Mark RHOSTS and RDISKS are assigned in correct format
	remote_ready="on"
elif (( ${#RHOSTS} != 0 )) && (( ${#RDISKS} == 0 )); then
        log_fail "There are no assigned disks for remote hosts, please try again."
elif (( ${#RHOSTS} == 0 )) && (( ${#RDISKS} != 0 )); then
	log_fail "Remote host assigning error, please try again."
fi

#
# setup iSCSI if iscsi option is enabled
#
if [[ -n $iscsi ]] && [[ $remote_ready == "on" ]] ; then
	iscsi=`$ECHO $iscsi | $TR "[:upper:]" "[:lower:]"`
	case $iscsi in
		remote)	
			# exclude local disks as testing targets
			DEVICES_IGNORE=$(find_disks)
			ZFS_HOST_DEVICES_IGNORE="${ZFS_HOST_DEVICES_IGNORE} \
				${DEVICES_IGNORE}"
			export ZFS_HOST_DEVICES_IGNORE
			# setup iscsi target at remote
			rsh_status "" ${rhosts[0]} \
				"$CHMOD a+x $RTEST_ROOT/iscsi_tsetup; \
				$RTEST_ROOT/iscsi_tsetup ${rdisks[0]}"
			if (( $? != 0 )) ; then
		       		log_fail "target setup failed"
			fi

			# setup iscsi initiator at local
			iscsi_isetup ${rhosts[0]}
			;;
		*)	 
			log_fail "parameter iscsi must be remote"
			;;
	esac
elif [[ -n $iscsi ]] ; then
	log_fail "RHOSTS and RDISKS are not assigned."
fi


default_cleanup_noexit

#
# Sweep available and not-in-use disks in the test system;
# And make sure all $DISKS are ready for zfs test
#
gooddisks=""
AVAIL_DISKS=$(find_disks)
(( ${#AVAIL_DISKS} == 0 )) && log_fail "No available disks for test."

# merge $DISK into $AVAIL_DISKS 
# because $AVAIL_DISKS has a default number limit of MAX_FINDDISKSNUM
# note: no need to do the merge when iscsi is set
if [[ $iscsi == "remote" ]]; then
	DISKS=$AVAIL_DISKS
else
	for disk in $DISKS; do
		$ECHO ${AVAIL_DISKS} | $GREP $disk > /dev/null 2>&1
		(( $? != 0 )) && AVAIL_DISKS="$disk ${AVAIL_DISKS}"
	done
fi

for disk in ${AVAIL_DISKS}; do
        $ZPOOL create -f foo_pool$$ $disk > /dev/null 2>&1
        # if disk is found not usable to create a pool, exclude it from
        # $DISKS paramter
        if (( $? == 0 )); then
                $ECHO $DISKS | $GREP $disk > /dev/null 2>&1
                (( $? == 0 )) && gooddisks="$disk $gooddisks"
                $ZPOOL destroy -f foo_pool$$
        fi
done
(( ${#gooddisks} == 0 )) && log_fail "No good disks for test."
DISKS="$gooddisks"

cat >> $configfile <<-EOF
export DISKS="$DISKS"
export KEEP="$KEEP"
export RUNTIME="$RUNTIME"
export iscsi=$iscsi
export ROOTPOOL="$ROOTPOOL"
export ROOTFS="$ROOTFS"
export ZPOOL_WRAPPER="${ZPOOL_WRAPPER}"
export ZFS_WRAPPER="${ZFS_WRAPPER}"
export ZPOOL="${ZPOOL}"
export ZFS="${ZFS}"
export ZPOOL_TEST_VERSION="${ZPOOL_TEST_VERSION}"
export ZFS_TEST_VERSION="${ZFS_TEST_VERSION}"
EOF

(( $? != 0 )) && log_fail Could not write to configure file, $configfile

# Create local zone and zone testing environment
#
if (( ${#zone_name} != 0 && ${#zone} != 0 )); then
	# The specified zone existed
	if $ZONEADM -z $zone_name list > /dev/null 2>&1; then
		if [[ $zone == existing ]]; then
			log_note "### WARNING: '$zone_name' already exists."

			# Recover pool and 5 container within it
			typeset -i i=0
			log_must $ZPOOL create -f $ZONE_POOL $DISKS
			while (( i < 5 )); do
				log_must $ZFS create $ZONE_POOL/$ZONE_CTR$i
				# Turn on 'zoned'
				log_must $ZFS set zoned=on $ZONE_POOL/$ZONE_CTR$i
				(( i += 1 ))
			done
			
			log_pass	
		elif [[ $zone == new ]]; then
			# Get current zone status
			status=$($ZONEADM -z $zone_name list -v | \
				$GREP "\<$zone_name\>" | $AWK '{print $3}')
			(( $? != 0 )) && \
				log_fail "Getting $zone_name status failed."

			# Remove this existed zone
			case $status in
			running)
				log_must $ZONEADM -z $zone_name halt
				log_must $ZONEADM -z $zone_name uninstall -F
				log_must $ZONECFG -z $zone_name delete -F
				;;
			installed)
				log_must $ZONEADM -z $zone_name uninstall -F
				log_must $ZONECFG -z $zone_name delete -F
				;;
			configured)
				log_must $ZONECFG -z $zone_name delete -F
				;;
			esac
		else
			log_fail "Invalid syntax for zone=new|existing"
		fi
	fi

	# Create pool and container, then create zone 
	zfs_zones_setup $zone_name $zone_root $zone_ip

	# check ${zone_root}/${zone_name}/root/export before creating user zone
	if [[ ! -d ${zone_root}/${zone_name}/root/export ]]; then
		log_must $ZLOGIN $zone_name $MKDIR /export
	fi

	# Create an non-super user 'zone' to run the test cases
	log_must $ZLOGIN $zone_name useradd -d /export/zone -m -s /bin/bash zone
fi

log_pass
