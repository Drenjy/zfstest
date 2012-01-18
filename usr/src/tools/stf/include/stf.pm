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

package		stf;
require		Exporter;
@ISA	=	qw(Exporter);

@EXPORT	=	qw(STF_PASS
		   STF_FAIL
		   STF_UNRESOLVED
		   STF_NOTINUSE
		   STF_UNSUPPORTED
		   STF_UNTESTED
		   STF_UNINITIATED
		   STF_NORESULT
		   STF_WARNING
		   STF_TIMED_OUT
		   STF_OTHER);

@EXPORT_OK =	@EXPORT;

require 5.005;
use strict;
use diagnostics;
use locale;

sub STF_PASS() {
	return $stf::PASS;
}

sub STF_FAIL() {
	return $stf::FAIL;
}

sub STF_UNRESOLVED() {
	return $stf::UNRESOLVED;
}

sub STF_NOTINUSE() {
	return $stf::NOTINUSE;
}

sub STF_UNSUPPORTED() {
	return $stf::UNSUPPORTED
}

sub STF_UNTESTED() {
	return $stf::UNTESTED
}

sub STF_UNINITIATED() {
	return $stf::UNINITIATED;
}

sub STF_NORESULT() {
	return $stf::NORESULT;
}

sub STF_WARNING() {
	return $stf::WARNING;
}
sub STF_TIMED_OUT() {
	return $stf::TIMED_OUT;
}

sub STF_OTHER() {
	return $stf::OTHER;
}

BEGIN {
	# set all result codes
	$stf::PASS=0;
	$stf::FAIL=1;
	$stf::UNRESOLVED=2;
	$stf::NOTINUSE=3;
	$stf::UNSUPPORTED=4;
	$stf::UNTESTED=5;
	$stf::UNINITIATED=6;
	$stf::NORESULT=7;
	$stf::WARNING=8;
	$stf::TIMED_OUT=9;
	$stf::OTHER=10;
}

