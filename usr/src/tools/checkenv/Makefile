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
# ident	"@(#)Makefile	1.8	08/11/21 SMI"
#

MACH		=	${HOST_ARCH:-%=%}
WD :sh		=	pwd

WS_ROOT_SH	=	export WD; WD=${WD}; \
			/usr/bin/ksh -p -c \
			'typeset wd=$${WD}; \
			while [[ ! -d $${wd}/src/tools ]] && \
				[[ $${wd:-"/"} != "/" ]]; \
			do wd=$${wd%/*}; done; \
			print $${wd%/usr};'
WS_ROOT		=	${WS_ROOT_SH:sh}

CHECKENV_SUITE	=	${WD}
CHECKENV_PROTO	=	${WS_ROOT}/proto/tools/checkenv

SUBDIRS		=	bin lib

all		:=	TARGET = install
install		:=	TARGET = install
clean		:=	TARGET = clean
clobber		:=	TARGET = clobber
unpackage	:=	STF_BUILD_PKG_OPTIONS = -r

#
# The following macros are used during "make package | unpackage"
#
STF_PKGMODE	= 	0022
STF_PKGARCHIVE	= 	${WS_ROOT}/packages
# Find path to stf_build_pkg tool
STF_BUILD_PKG:sh= 	/usr/bin/ksh -p -c \
			'pkgtool="$(whence -p stf_build_pkg)"; \
			echo ${pkgtool};'
# Find path to STF root directory
STF_TOOLS:sh	= 	/usr/bin/ksh -p -c \
			'pkgtool="$(whence -p stf_build_pkg)"; \
			stfpath="${pkgtool%%/bin/*}"; echo ${stfpath};'

install all clean clobber: $(SUBDIRS)

$(SUBDIRS)::
	cd $@; ${MAKE} ${TARGET} \
	CHECKENV_SUITE=${CHECKENV_SUITE} \
	CHECKENV_PROTO=${CHECKENV_PROTO}/$(@F)

package: install

package unpackage:
	@if [ -z "$(STF_BUILD_PKG)" ]; then \
		echo "ERROR: Path to stf_build_pkg tool needs to be added" \
		"to PATH."; \
		exit 1; \
	fi
	/bin/env \
		STF_PKGARCHIVE=${STF_PKGARCHIVE} \
		STF_SUITE=${CHECKENV_SUITE} \
		STF_SUITE_PROTO=${CHECKENV_PROTO} \
		STF_MACH_BUILD_MODES=none \
		STF_SUITE_BUILD_MODES=none \
		STF_MACH=${MACH} \
		STF_PKGMODE=${STF_PKGMODE} \
		STF_CONFIG_INPUTS=${STF_TOOLS}/etc/BuildConfig.master \
		STF_TOOLS=${STF_TOOLS} \
		${STF_BUILD_PKG} ${STF_BUILD_PKG_OPTIONS}

uninstall:
	$(RM) -rf ${CHECKENV_PROTO}

