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
# ident	"@(#)Makefile	1.2	07/01/09 SMI"
#

ALL_SUBDIRS :sh = /bin/ls */[Mm]akefile | sed 's@/[Mm]akefile@@g'

EXCLUDE_SUBDIRS=

# This brain dead FOO=... SUBDIRS= $(FOO:sh) is needed to expand the
# ALL_SUBDIRS and EXCLUDE_SUBDIRS variables. They don't get exported to
# a simple VARIABLE :sh = ... expansion.

FOO = \
	set +e; \
	if [ -n "$(EXCLUDE_SUBDIRS)" ]; then \
		for i in $(ALL_SUBDIRS); do \
			for j in $(EXCLUDE_SUBDIRS) NOMATCHME; do \
				if [ "$$i" = "$$j" ]; then \
					i=""; \
					break; \
				fi; \
			done; \
			echo $$i; \
		done; \
	else \
		echo $(ALL_SUBDIRS); \
	fi; \
	exit 0

SUBDIRS = $(FOO:sh)

STF_BUILD_SUBDIRS=$(SUBDIRS)
STF_EXECUTE_SUBDIRS=$(SUBDIRS)

include $(STF_TOOLS)/Makefiles/Makefile.master
