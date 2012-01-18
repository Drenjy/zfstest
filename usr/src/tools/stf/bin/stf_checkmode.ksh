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

mode=$1
kernel=$2
if [ -z "$kernel" ]; then
	kernel=`isainfo -k`
fi

case $kernel in

sparcv9 )
	[[ $mode = sparcv9 ]] && exit 0
	[[ $mode = sparc ]] && exit 0
	[[ $mode = sparc-f64 ]] && exit 0
	;;
sparc  )
	[[ $mode = sparc ]] && exit 0
	[[ $mode = sparc-f64 ]] && exit 0
	;;
i386    )
	[[ $mode = i386 ]] && exit 0
	[[ $mode = i386-f64 ]] && exit 0
	;;
amd64   )
	[[ $mode = i386 ]] && exit 0
	[[ $mode = i386-f64 ]] && exit 0
	[[ $mode = amd64 ]] && exit 0
	[[ $mode = amd64-gcc ]] && exit 0
	;;
esac

exit 1
