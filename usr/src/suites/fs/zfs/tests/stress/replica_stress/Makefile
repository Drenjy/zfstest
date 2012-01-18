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

SUBDIRS=mirror_stress_002 mirror_stress_003 mirror_stress_004 \
	mirror_stress_005 mirror_stress_006 \
	raidz_stress_001 raidz_stress_002 \
	slog_stress_001 slog_stress_002

STF_BUILD_SUBDIRS=$(SUBDIRS)
STF_EXECUTE_SUBDIRS=$(SUBDIRS)

STF_ENVFILES=default.cfg
STF_INCLUDES=replica_stress_common.kshlib

include ${STF_TOOLS}/Makefiles/Makefile.master
