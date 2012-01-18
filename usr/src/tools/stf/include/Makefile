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
# Copyright (c) 2012 by Delphix. All rights reserved.
#

STF_FILEMODE=444

STF_DATAFILES=stf.h stf.shlib stf.tcllib stf.pm stf_common.kshlib stf.explib \
	stf.shlib errors.kshlib mstf.h mstf.tcllib testgen.kshlib

all: errors.kshlib

errors.kshlib:
	echo "# Copyright `/usr/bin/date +%Y` Sun Microsystems, Inc.  All" \
	"rights reserved." > errors.kshlib; \
	echo "# Use is subject to license terms." >> errors.kshlib; \
	/usr/xpg4/bin/awk '/^#define[[:space:]]E/ { if ($$3 ~ /[0-9]+/) \
	{ print $$2 "=" $$3; } else { print $$2 "=$$" $$3 } }' \
	/usr/include/sys/errno.h >> errors.kshlib

STF_DONTBUILDMODES=true

include ${STF_TOOLS_MAKEFILES}/Makefile.master

