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
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# Copyright (c) 2012 by Delphix. All rights reserved.
#
STF_CFLAGS += -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE
STF_LDFLAGS += -ldevid

STF_EXECUTABLES=chg_usr_exec \
	devname2devid \
	dir_rd_update \
	file_check \
	file_trunc \
	file_write \
	largest_file \
	mkbusy \
	mktree \
	mmapwrite \
	randfree_file \
	readmmap \
	rename_dir \
	rm_lnkcnt_zero_file

STF_BUILD_SUBDIRS=scripts

include $(STF_TOOLS)/Makefiles/Makefile.master
