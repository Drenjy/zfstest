#! /usr/perl5/bin/perl
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

## File: stf_compare
## compare the results from an existing baseline file and 
## a new journal file in baseline format.

$Basekey = '_bAseLinE_STF';

if ($#ARGV != 1) {
	die "usage: $0 basenamefile newbasenamefile\n";
}

$EXP_BASE = $ARGV[0];
$NEW_BASE = $ARGV[1];

open(EXP_BASE, $EXP_BASE) || die "$0: can't open file, $EXP_BASE\n";
open(NEW_BASE, $NEW_BASE) || die "$0: can't open file, $NEW_BASE\n";

$check_key = <EXP_BASE>;
if ($check_key !~ /^$Basekey/) {
	die "$0: $EXP_BASE is not in baseline format, use stf_filter before proceeding.\n";
}

$check_key = <NEW_BASE>;
if ($check_key !~ /^$Basekey/) {
	die "$0: $NEW_BASE, is not in baseline format, use stf_filter before proceeding.\n";
}

## load up the associative array of test numbers and results for the new file  ##
while(<NEW_BASE>) {
	split;
	$new_key = shift @_; 
##      build an array of only the name key without results ##
	$newnames {$new_key} = 1;
##	strip off the total count and use only result name  ##
	foreach $result(@_) {
		($resultname, $count)= split(/:/, $result);
		$newresult {$new_key, $resultname} = 1;
	}
}

close NEW_BASE;

## load up the associative array of test numbers and results for the baseline file  ##

while(<EXP_BASE>) {
	split;
	$exp_key = shift @_; 
##	strip off the total count and use only result name  ##
	foreach $result(@_) {
		($resultname, $count)= split(/:/, $result);
		$expresult{$exp_key, $resultname} = 1;
	}
	$match_found = $newnames{$exp_key};
	if (!$match_found) {
		print "< ", $exp_key, "\n";
	}
}

close EXP_BASE;

## No need to sort the arrays because the baseline format is already sorted ##

## Find the differences in the new results array ##
grep($tmp_array1{$_}++, %expresult);
@diffs = grep(!$tmp_array1{$_}, %newresult);
$onetime = 0;

foreach $diffline (@diffs) {
	($id, $resultname) = split(/\034/, $diffline);
	print "> ", $id, "\t", $resultname, "\n";
}
