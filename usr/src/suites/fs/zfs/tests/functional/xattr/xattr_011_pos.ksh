#!/bin/ksh -p
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
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)xattr_011_pos.ksh	1.1	07/02/06 SMI"
#

. $STF_SUITE/include/libtest.kshlib
. $STF_SUITE/tests/functional/xattr/xattr_common.kshlib

################################################################################
#
# __stc_assertion_start
#
# ID:  xattr_011_pos
#
# DESCRIPTION:
#
# Basic applications work with xattrs: cpio cp find mv pax tar
# 
# STRATEGY:
#	1. For each application
#       2. Create an xattr and archive/move/copy/find files with xattr support
#	3. Also check that when appropriate flag is not used, the xattr
#	   doesn't get copied
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING_STATUS: COMPLETED (2006-12-15)
#
# __stc_assertion_end
#
################################################################################

function cleanup {

	log_must $RM $TESTDIR/myfile.$$
}

log_assert "Basic applications work with xattrs: cpio cp find mv pax tar"
log_onexit cleanup

# Create a file, and set an xattr on it. This file is used in several of the
# test scenarios below.
log_must $TOUCH $TESTDIR/myfile.$$
create_xattr $TESTDIR/myfile.$$ passwd /etc/passwd


# For the archive applications below (tar, cpio, pax)
# we create two archives, one with xattrs, one without
# and try various cpio options extracting the archives
# with and without xattr support, checking for correct behaviour


log_note "Checking cpio"
log_must $TOUCH $TESTDIR/cpio.$$
create_xattr $TESTDIR/cpio.$$ passwd /etc/passwd
$ECHO $TESTDIR/cpio.$$ | $CPIO -o@ > /tmp/xattr.$$.cpio
$ECHO $TESTDIR/cpio.$$ | $CPIO -o > /tmp/noxattr.$$.cpio

# we should have no xattr here
log_must $CPIO -iu < /tmp/xattr.$$.cpio
log_mustnot eval "$RUNAT $TESTDIR/cpio.$$ $CAT passwd > /dev/null 2>&1"

# we should have an xattr here
log_must $CPIO -iu@ < /tmp/xattr.$$.cpio
log_must eval "$RUNAT $TESTDIR/cpio.$$ $CAT passwd > /dev/null 2>&1"

# we should have no xattr here
log_must $CPIO -iu < /tmp/noxattr.$$.cpio
log_mustnot eval "$RUNAT $TESTDIR/cpio.$$ $CAT passwd > /dev/null 2>&1"

# we should have no xattr here
log_must $CPIO -iu@ < /tmp/noxattr.$$.cpio
log_mustnot eval "$RUNAT $TESTDIR/cpio.$$ $CAT passwd > /dev/null 2>&1"
log_must $RM $TESTDIR/cpio.$$ /tmp/xattr.$$.cpio /tmp/noxattr.$$.cpio



log_note "Checking cp"
# check that with the right flag, the xattr is preserved
log_must $CP -@ $TESTDIR/myfile.$$ $TESTDIR/myfile2.$$
compare_xattrs $TESTDIR/myfile.$$ $TESTDIR/myfile2.$$ passwd
log_must $RM $TESTDIR/myfile2.$$

# without the right flag, there should be no xattr
log_must $CP $TESTDIR/myfile.$$ $TESTDIR/myfile2.$$
log_mustnot eval "$RUNAT $TESTDIR/myfile2.$$ $LS passwd > /dev/null 2>&1"
log_must $RM $TESTDIR/myfile2.$$



log_note "Checking find"
# create a file without xattrs, and check that find -xattr only finds
# our test file that has an xattr.
log_must $MKDIR $TESTDIR/noxattrs
log_must $TOUCH $TESTDIR/noxattrs/no-xattr

$FIND $TESTDIR -xattr | $GREP myfile.$$
if [ $? -ne 0 ]
then
	log_fail "find -xattr didn't find our file that had an xattr."
fi
$FIND $TESTDIR -xattr | $GREP no-xattr
if [ $? -eq 0 ]
then
	log_fail "find -xattr found a file that didn't have an xattr."
fi
log_must $RM -rf $TESTDIR/noxattrs



log_note "Checking mv"
# mv doesn't have any flags to preserve/ommit xattrs - they're
# always moved.
log_must $TOUCH $TESTDIR/mvfile.$$
create_xattr $TESTDIR/mvfile.$$ passwd /etc/passwd
log_must $MV $TESTDIR/mvfile.$$ $TESTDIR/mvfile2.$$
verify_xattr $TESTDIR/mvfile2.$$ passwd /etc/passwd
log_must $RM $TESTDIR/mvfile2.$$


log_note "Checking pax"
log_must $TOUCH $TESTDIR/pax.$$
create_xattr $TESTDIR/pax.$$ passwd /etc/passwd
log_must $PAX -w -f $TESTDIR/noxattr.pax $TESTDIR/pax.$$
log_must $PAX -w@ -f $TESTDIR/xattr.pax $TESTDIR/pax.$$
log_must $RM $TESTDIR/pax.$$

# we should have no xattr here
log_must $PAX -r -f $TESTDIR/noxattr.pax
log_mustnot eval "$RUNAT $TESTDIR/pax.$$ $CAT passwd > /dev/null 2>&1"
log_must $RM $TESTDIR/pax.$$ 

# we should have no xattr here
log_must $PAX -r@ -f $TESTDIR/noxattr.pax
log_mustnot eval "$RUNAT $TESTDIR/pax.$$ $CAT passwd > /dev/null 2>&1"
log_must $RM $TESTDIR/pax.$$


# we should have an xattr here
log_must $PAX -r@ -f $TESTDIR/xattr.pax
verify_xattr $TESTDIR/pax.$$ passwd /etc/passwd
log_must $RM $TESTDIR/pax.$$

# we should have no xattr here
log_must $PAX -r -f $TESTDIR/xattr.pax
log_mustnot eval "$RUNAT $TESTDIR/pax.$$ $CAT passwd > /dev/null 2>&1"
log_must $RM $TESTDIR/pax.$$ $TESTDIR/noxattr.pax $TESTDIR/xattr.pax


log_note "Checking tar"
log_must $TOUCH $TESTDIR/tar.$$
create_xattr $TESTDIR/tar.$$ passwd /etc/passwd
log_must $TAR cf $TESTDIR/noxattr.tar $TESTDIR/tar.$$
log_must $TAR c@f $TESTDIR/xattr.tar $TESTDIR/tar.$$
log_must $RM $TESTDIR/tar.$$

# we should have no xattr here
log_must $TAR xf $TESTDIR/xattr.tar
log_mustnot eval "$RUNAT $TESTDIR/tar.$$ $CAT passwd > /dev/null 2>&1"
log_must $RM $TESTDIR/tar.$$

# we should have an xattr here
log_must $TAR x@f $TESTDIR/xattr.tar
verify_xattr $TESTDIR/tar.$$ passwd /etc/passwd
log_must $RM $TESTDIR/tar.$$

# we should have no xattr here
log_must $TAR xf $TESTDIR/noxattr.tar
log_mustnot eval "$RUNAT $TESTDIR/tar.$$ $CAT passwd > /dev/null 2>&1"
log_must $RM $TESTDIR/tar.$$

# we should have no xattr here
log_must $TAR x@f $TESTDIR/noxattr.tar
log_mustnot eval "$RUNAT $TESTDIR/tar.$$ $CAT passwd > /dev/null 2>&1"
log_must $RM $TESTDIR/tar.$$ $TESTDIR/noxattr.tar $TESTDIR/xattr.tar


log_assert "Basic applications work with xattrs: cpio cp find mv pax tar"
