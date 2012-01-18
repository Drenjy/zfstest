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

WD :sh			= pwd

STF_TOOLS_BUILD		= ${WD}/build
STF_TOOLS_ETC		= ${WD}/etc
STF_TOOLS_MAKEFILES	= ${WD}/Makefiles

STF_PKGMODE	= 0022

all	:=	TARGET	= install
clean	:=	TARGET	= clean
clobber	:=	TARGET	= clobber
install	:=	TARGET	= install
lint	:=	TARGET	= lint
uninstall	:=	TARGET	= uninstall
package		:=	TARGET	= package
unpackage	:=	TARGET	= unpackage

install all clean lint uninstall package unpackage: buildstrap target

clobber: buildstrap target cleanstrap

target:
	${MAKE} -f Makefile.stf ${TARGET} \
	    STF_TOOLS_BUILD=${STF_TOOLS_BUILD}\
	    STF_TOOLS_ETC=${STF_TOOLS_ETC} \
	    STF_TOOLS_MAKEFILES=${STF_TOOLS_MAKEFILES}

buildstrap:
	cd ${STF_TOOLS_BUILD}; ${MAKE} -f Makefile.buildstrap all

cleanstrap:
	cd ${STF_TOOLS_BUILD}; ${MAKE} -f Makefile.buildstrap clean
