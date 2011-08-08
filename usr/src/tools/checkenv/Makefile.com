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
# ident	"@(#)Makefile.com	1.3	07/05/16 SMI"
#

CHMOD		=	/usr/bin/chmod -f
CP		=	/usr/bin/cp -f
RM		=	/usr/bin/rm -f
INSTALL		=	/usr/sbin/install
DIRMODE		=	777
EXECMODE	=	555

WD: sh		=	pwd

CHECKENV_PROTO_TARGETS	= $(CHECKENV_TARGETS:%=$(CHECKENV_PROTO)/%)

install: $(CHECKENV_PROTO_TARGETS)

$(CHECKENV_PROTO_TARGETS): $(CHECKENV_PROTO) $(CHECKENV_TARGETS)

$(CHECKENV_PROTO)::
	$(INSTALL) -s -d -m $(DIRMODE) $(@)

$(CHECKENV_PROTO_TARGETS):
	$(CHMOD) +w $(@)
	$(INSTALL) -s -m $(EXECMODE) -f $(@D) $(@F)

clean:
	$(RM) $(CHECKENV_TARGETS)

clobber:
	$(RM) $(CHECKENV_TARGETS)

.SUFFIXES: .ksh

.ksh:
	$(CP) $< $@
	$(CHMOD) +x $@
