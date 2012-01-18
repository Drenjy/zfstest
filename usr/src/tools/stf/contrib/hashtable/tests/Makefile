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

STF_PROTODIR=		contrib/hashtable/tests
STF_EXECUTABLES=	basic generate
STF_DATAFILES=		basic.commands delete.commands insert.commands \
			locate.commands resize.commands

include ${STF_TOOLS_MAKEFILES}/Makefile.master

STF_CFLAGS= 		${MT_FLAG} \
			-I ${STF_SRC} \
			-I ${STF_SUITE}/contrib/hashtable/include

STF_LDFLAGS=		-L ${STF_SUITE_PROTO}/contrib/lib/${STF_BUILD_MODE} \
			-lhashtable

