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
# ident	"@(#)Makefile	1.10	07/04/12 SMI"
#

#
# Define which files need to be propogated to the proto area (TBINTOOLS).
# Normally shell scrips should be listed in the SHFILES macro, but since we
# need some of them for "bootstrap" purposes, and SHFILES get removed when
# "make clobber" occurs, some of the script files are listed as DATAFILES so
# they don't get cleaned.
#

STF_BUILD_ONLY=sparc i386

STF_LDFLAGS=-lstf

STF_EXECUTABLES=stf_gosu stf_jnl_assert_end stf_jnl_assert_start \
stf_jnl_context stf_jnl_end stf_jnl_env stf_jnl_msg stf_jnl_start \
stf_jnl_testcase_end stf_jnl_testcase_start stf_jnl_totals stf_timeout \
stf_compare stf_compare3 stf_filter stf_creategosu stf_execute \
stf_configure stf_build stf_unconfigure stf_checkmode stf_jnl_spec \
stf_build_pkg stf_addassert stf_add_static_testcases mstf_addassert \
mstf_getvar mstf_setvar mstf_sync mstf_launch mstf_syncserv

stf_gosu:=	STF_LDFLAGS=

mstf_getvar:=	STF_LDFLAGS=-lstf -lmstf -lsocket -lnsl
mstf_setvar:=	STF_LDFLAGS=-lstf -lmstf -lsocket -lnsl
mstf_sync:=	STF_LDFLAGS=-lstf -lmstf -lsocket -lnsl

include $(STF_TOOLS_MAKEFILES)/Makefile.master
