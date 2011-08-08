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
# ident	"@(#)Makefile	1.2	09/06/22 SMI"
#

STF_USER_CONFIGURE=
STF_ROOT_CONFIGURE=

STF_ROOT_SETUP=setup
STF_USER_SETUP=

STF_ROOT_CLEANUP=cleanup
STF_USER_CLEANUP=

STF_ROOT_TESTCASES=slog_001_pos slog_002_pos slog_003_pos slog_004_pos \
	slog_005_pos slog_006_pos slog_007_pos slog_008_neg slog_009_neg \
	slog_010_neg slog_011_neg slog_012_neg slog_013_pos slog_014_pos
STF_USER_TESTCASES=

STF_ENVFILES=slog.cfg
STF_INCLUDES=slog.kshlib

STF_DONTBUILDMODES=true

include $(STF_TOOLS)/Makefiles/Makefile.master
