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
# ident	"@(#)stf_rmfiles.ksh	1.3	07/04/12 SMI"
#

#
# Ensure that SOME file names were passed. Otherwise the ls to get the list
# of files will get everything in the directory.
#
if (( ${#} == 0 )); then
	exit 0
fi

#
# Remove the files named in the parameters.
# Note: Directories will not be removed!
#
typeset filelist="$(ls -1 ${@} 2> /dev/null)"

if (( ${#filelist} > 0 )); then
	command="rm -f ${filelist}"
	print ${command}
	${command}
fi
