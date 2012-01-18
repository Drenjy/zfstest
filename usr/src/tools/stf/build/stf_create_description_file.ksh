#! /usr/bin/ksh -p
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

cat > /tmp/stf_description.$$ <<EOF
STF_BUILD_MODES="` echo $1`"
STF_EXECUTE_MODES="` echo $2`"

STF_ROOT_CHECKENV="$3"
STF_USER_CHECKENV="$4"
STF_ROOT_CONFIGURE="$5"
STF_USER_CONFIGURE="$6"
STF_ROOT_UNCONFIGURE="$7"
STF_USER_UNCONFIGURE="$8"
STF_ROOT_SETUP="$9"
STF_USER_SETUP="${10}"
STF_ROOT_CLEANUP="${11}"
STF_USER_CLEANUP="${12}"
STF_TESTCASES_GEN="${13}"
STF_ROOT_TESTCASES="${14}"
STF_USER_TESTCASES="${15}"
STF_DATAFILES="${16}"
STF_ENVFILES="${17}"
STF_CONFIGFILES="${18}"
STF_EXECUTE_SUBDIRS="${19}"
STF_DONTBUILDMODES="${20}"
MSTF_ROLES="${21}"
MSTF_ENVMAPS="${22}"
STF_ROOT_CASEFILES="${23}"
STF_USER_CASEFILES="${24}"
EOF

/usr/bin/cp -f /tmp/stf_description.$$ stf_description
/usr/bin/rm -f /tmp/stf_description.$$
