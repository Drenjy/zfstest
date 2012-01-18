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


usage()
{
	typeset bin="$0"
	bin=${bin##*/}
	cat <<-EOF
		Usage:
		$bin help
		$bin install   [ -z <zonename> ] [ -s ] [ <forcepriv_path> ]
		$bin uninstall [ -z <zonename> ] [ <forcepriv_path> ]
	EOF
}


ppriv_paths()
{
	typeset subcommand=$1
	typeset f d
	( cd /usr/bin ; find . -type f -name ppriv ) | \
	while read f ; do
		f=${f#./}
		d=${f%ppriv}
		d=${d%/}
		case $subcommand in
		install)    printf "%s\n" $d $f ;;
		uninstall)  printf "%s\n" $f $d ;;
		esac
	done
}


zone_root()
{
	typeset zone=$1
	typeset this_zone=$(/bin/zonename)
	if [[ $zone == $this_zone ]]; then
		return 0
	elif [[ $this_zone == global ]]; then
		echo "$(/usr/sbin/zonecfg -z $zone info zonepath | \
		    /bin/cut -d" " -f2)/root"
		return 0
	fi
	return 1
}


if [[ $# -eq 0 ]]; then
	usage
	exit 1
else
	subcommand="$1"
	shift
fi
case "$subcommand" in
help)
	usage
	exit 0
	;;
install|uninstall)
	set -A zone_list
	setuid=false
	while getopts z:s opt
	do
		case $opt in
		z)
			set -A zone_list ${zone_list[@]} $OPTARG
			;;
		s)
			setuid=true
			;;
		?)
			usage
			exit 1
			;;
		esac
	done
	shift $(($OPTIND - 1))
	if [[ ${#zone_list[@]} -eq 0 ]]; then
		set -A zone_list $(/usr/sbin/zoneadm list)
	fi
	;;
*)
	usage
	exit 1
	;;
esac

if [[ "$1" != "" ]]; then
	fp_path="$1"
	shift
elif [[ "$RUNWATTR_FORCEPRIV" != "" ]]; then
	fp_path="$RUNWATTR_FORCEPRIV"
else
	fp_path="/var/tmp/SUNWstc-runwattr/forcepriv"
fi

fp_dir=${fp_path%/*}
fp_file=${fp_path##*/}

set -A path_list $(ppriv_paths $subcommand)

for zone in ${zone_list[@]} ; do
	zone_root=$(zone_root $zone)
	if [[ $subcommand == install ]]; then
		if [[ ! -d ${zone_root}${fp_dir} ]]; then
			mkdir -p ${zone_root}${fp_dir}
		fi
	fi
	for path_item in ${path_list[@]} ; do
		if [[ -f /usr/bin/$path_item ]]; then
			if [[ $path_item = */* ]]; then
				isadir=${path_item%/*}/
			else
				isadir=""
			fi
			dest=${zone_root}${fp_dir}/${isadir}${fp_file}
			case $subcommand in
			install)
				if [[ ! -f $dest ]]; then
					cp /usr/bin/$path_item $dest
					if [[ $setuid == true ]]; then
						chown root $dest
						chgrp root $dest
						if [[ -z $isadir ]]; then
							chmod 06555 $dest
						else
							chmod 00555 $dest
						fi
					fi
				fi
				;;
			uninstall)
				rm -f $dest >/dev/null 2>&1
				;;
			esac
		elif [[ -d /usr/bin/$path_item ]]; then
			dest=${zone_root}${fp_dir}/$path_item
			case $subcommand in
			install)
				if [[ ! -d $dest ]]; then
					mkdir $dest
					if [[ $setuid == true ]]; then
						chown root $dest
						chgrp root $dest
						chmod 0755 $dest
					fi
				fi
				;;
			uninstall)
				rmdir $dest >/dev/null 2>&1
				;;
			esac
		fi
	done
	if [[ $subcommand == uninstall ]]; then
		rmdir ${zone_root}${fp_dir} >/dev/null 2>&1
	fi
done
