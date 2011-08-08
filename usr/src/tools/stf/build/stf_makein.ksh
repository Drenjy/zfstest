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
# ident	"@(#)stf_makein.ksh	1.3	07/04/13 SMI"
#

#
# If a directory exists, and there is a Makefile in it, then change to that
# directory and invoke the command passed.
#
# Usage: makein.ksh <dir> <make arg [<make arg> [...]]>
#
typeset result

if [[ ! -d "${1}" ]]; then
	print "**** Warning: Directory ${1} not present."
	return 0
else
	"cd" $1
	shift
	print "(BEGIN)\tMake in ${PWD}"
	print "${@}"
	"${@}"
	result=${?}
	print "(END)\tMake in ${PWD}"
	return ${result}
fi
