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
# ident	"@(#)stf_creategosu.ksh	1.5	07/04/12 SMI"
#

print -n "\nCreating stf_gosu utility: $2 \n"

typeset me=$(whence -p $0)

if (( $(/usr/xpg4/bin/id -u) != 0 )); then
	print -n "You must be root to create $2\nPlease Enter Root "
	eval exec su root -c \'$me "$@"\'	
fi

/usr/bin/cp -f $1   $2 &&
/usr/bin/chown root $2 &&
/usr/bin/chmod 4755 $2

exit $?
