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
# ident	"@(#)Makefile	1.5	08/11/03 SMI"
#

STF_BUILD_SUBDIRS=include .WAIT bin tests etc
STF_EXECUTE_SUBDIRS=tests

STF_ROOT_CONFIGURE=configure
STF_ROOT_UNCONFIGURE=unconfigure
STF_USER_CONFIGURE=user_configure
STF_CONFIGFILES=config.vars

STF_ROOT_SETUP=setup
STF_ROOT_CLEANUP=cleanup

STF_ROOT_CHECKENV=checkenv_def

STF_DATAFILES=README

STF_ENVFILES=default.cfg commands.cfg

STF_EXECUTABLES=chk_pkg iscsi_tsetup

# XXX - workaround; needs to be removed once stf build issues are fixed
STF_DONTBUILDMODES=true

include $(STF_TOOLS)/Makefiles/Makefile.master

commands.cfg: commands.txt
	ksh -p translatecommands.ksh commands.txt > commands.cfg
