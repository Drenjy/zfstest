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

## This is copied from the perl library as a workaround for missing libraries
## on target machines at the moment.

;# getopts.pl - a better getopt.pl

;# Usage:
;#      do Getopts('a:bc');  # -a takes arg. -b & -c not. Sets opt_* as a
;#                           #  side effect.

sub Getopts {
    local($argumentative) = @_;
    local(@args,$_,$first,$rest);
    local($errs) = 0;
    local($[) = 0;

    @args = split( / */, $argumentative );
    while(@ARGV && ($_ = $ARGV[0]) =~ /^-(.)(.*)/) {
	($first,$rest) = ($1,$2);
	$pos = index($argumentative,$first);
	if($pos >= $[) {
	    if($args[$pos+1] eq ':') {
		shift(@ARGV);
		if($rest eq '') {
		    ++$errs unless @ARGV;
		    $rest = shift(@ARGV);
		}
		eval "\$opt_$first = \$rest;";
	    }
	    else {
		eval "\$opt_$first = 1";
		if($rest eq '') {
		    shift(@ARGV);
		}
		else {
		    $ARGV[0] = "-$rest";
		}
	    }
	}
	else {
	    print STDERR "Unknown option: $first\n";
	    ++$errs;
	    if($rest ne '') {
		$ARGV[0] = "-$rest";
	    }
	    else {
		shift(@ARGV);
	    }
	}
    }
    $errs == 0;
}

## File: stf_short
## compare the results from an existing baseline file, previous filtered journal file,
## a new filtered journal file in baseline format.

$Basekey = '_bAseLinE_STF';
$Noresult = 'NORESULT';

&Getopts('b:p:');

$EXP_BASE = $opt_b;
$PRV_BASE = $opt_p; 
$NEW_BASE = $ARGV[0];

if (!$NEW_BASE) {
        die "usage: $0 [ -b basenamefile ] [ -p previousbasenamefile ] newbasenamefile\n";
}

&LoadResults($NEW_BASE, *newresults, *newnames);


if ($PRV_BASE) {
	&LoadResults($PRV_BASE, *prvresults, *prvnames);
}
&LoadResults($EXP_BASE, *expresults, *expnames);

foreach $test (keys %expnames) {
	if ($PRV_BASE && !$prvnames{$test}) { 
		$prvnames{$test} = $Noresult;
		$prvresults{$test, $Noresult} = 1;
	}
	if (!$newnames{$test}) {
		$newnames{$test} = $Noresult;
		$newresults{$test, $Noresult} = 1;
	}
}

## Find the differences in the new results array and the prev results array ##
foreach $newdiff (keys %newresults) {
	if (!$expresults{$newdiff}) {
		($test, $result) = split(/\034/, $newdiff);
		$diffs_tests{$test} = 1;
	}
}

foreach $prvdiff (keys %diffs_prv) {
	if (!$expresults{$prvdiff}) {
		($test,$result) = split(/\034/, $prvdiff);
		$diffs_tests{$test} = 1;
	}
}
## Iterate on the keys looking for entries in each of the names arrays ##
foreach $test (sort keys(%diffs_tests)) {
	if (!$expnames{$test}) {
		$expnames{$test} = $Noresult;
	}
	print "$test $newnames{$test} $prvnames{$test} $expnames{$test}\n";
}

## Subroutine: LoadResults
## Arguments: 
##		<BaseName> - Name of filtered journal file
##		<Results>  - Name of results array to be loaded from journal file
##		<Names>	   - Name of Test-name array loaded from journal file
## Action:
##		Open filtered journal file, check for baseline format, load Results, and Names arrays.
##

sub LoadResults {

local($BaseName, *Results, *Names) = @_;

## open(BASE, $BaseName) || print "$0: can't open file, $BaseName\n";
open(BASE, $BaseName) || return;

$check_key = <BASE>;
if ($check_key !~ /^$Basekey/) {
        die "$0: $BaseName, is not in baseline format, use stf_filter before proceeding.\n";
}

## load up the associative array of test numbers and results for the journal file  ##
while(<BASE>) {
        split;
        $key = shift @_;
##      build an array of only the name key without results ##
##      strip off the total count and use only result name  ##
        foreach $res (@_) {
                ($resultname, $count)= split(/:/, $res);
                $Results {$key, $resultname} = 1;
                $Names {$key} = join(',', $resultname, $Names{$key});
        }
        substr($Names{$key}, -1, 1) = "";
}
close BASE;

}

