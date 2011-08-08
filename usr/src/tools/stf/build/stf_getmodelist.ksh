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
# ident	"@(#)stf_getmodelist.ksh	1.4	07/04/12 SMI"
#

allmodes=$1
buildonly=$2
dontbuild=$3

integer yes

for mode in $allmodes ; do
	(( yes = 1 ))
	if [[ -n $buildonly ]] ; then
		(( yes = 0 ))	
		for only in $buildonly ; do
			if [[ "$mode" = "$only" ]] ; then
				(( yes = 1 ))
				break
			fi
		done
	fi
	(( yes == 0 )) && continue
	for dont in $dontbuild ; do
		if [[ "$mode" = "$dont" ]] ; then
			(( yes = 0 ))
			continue
		fi
	done
	(( yes == 1 )) && print -n "$mode "
done

exit 0
