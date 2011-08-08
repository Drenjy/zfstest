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
# ident	"@(#)stf_filter.pl	1.9	07/04/12 SMI"
#

# File: stf_filter
## read in journal file and filter out important stuff

###############################################################################
# SUBROUTINES
###############################################################################

#####################################################################
# subroutine name: is_testcase_match 
# arg1: the full path of testcase to be compared
# arg2: match pattern
#
# returns: 1 (match), 0 (not match)
#
# just use regular expression comparition.
#####################################################################
sub is_testcase_match
{
	return ( $_[0] =~ /$_[1]/ )?1:0;
}

#####################################################################
# subroutine name: is_code_match 
# arg1: the result code, see @result_codes
# arg2: match code
# arg3: flags of reverse match. 0 (not reverse), 1(reverse)
#
# returns: 1 (match), 0 (not match)
#####################################################################
sub is_code_match
{
	return ( $_[2] == 0 )?
		(($_[0] eq $_[1])?1:0):
		(($_[0] ne $_[1])?1:0);
}

#####################################################################
# subroutine name: out_usage 
# args: none
#
# returns: none
#
#print out usage info for stf_filter.
#####################################################################
sub out_usage
{
	die "usage: $Progname [-p pattern] [-r resultcode] [-v verbose] [-s] \
\t journalfile {journalfile} \
\
options: \
-p pattern \
	Specify one pattern to be used during the search \
	for the name of testcases (entire relative path under  \
	\"suites\"). for example: \
 \
	-p \"abc/001\" , any testcase name include \"abc/001\" will matched; \
	-p \"001\$\", any testcase name end with \"001\" will matched; \
 \
	PRE (Perl Regular Expression) syntax supported. \
 \
-r resultcode \
	Specify one result code (or its opposite) to be used \
	during the search, can be any valid STF result code \
	within \"PASS\", \"FAIL\", \"UNRESOLVED\", \"NOTINUSE\",  \
	\"UNSUPPORTED\", \"UNTESTED\", \"UNINITIATED\", \"NORESULT\", \
	\"WARNING\", \"TIMED_OUT\", and \"OTHER\". (case sensitive) \
	The reverse match can be implement by leading with \"!\", \
	single quote with resultcode is recommended. for example: \
 \
	-r PASS, any testcase whose result is PASS will matched. \
	-r '!PASS', any testcase whose result is NOT PASS will matched. \
 \
-v verbose \
	Specify which kinds of verbose info should print out.  \
	Can set to be \"all\", or any combination within \"stdout\", \"stderr\",  \
	and other valid header target which between \"Test_Case_Start\" \
	and \"Test_Case_End\" in journal files. for example: \
 \
	-v \"stdout\", only messages of stdout will print. \
	-v \"stdout|stderr\", any messages of stdout or stderr will print. \
	-v \"all\", all verbose messages will print. \
 \
-s \
	Strip the header of verbose output, such as \"stdout|\", \"stderr|\", etc. \
	To make a cleaner output. (without -s, header will reserved as in file) \
";
}

$Progname = 'stf_filter';
$Basekey = '_bAseLinE_STF';

@result_codes=(
	"PASS", 
	"FAIL", 
	"UNRESOLVED", 
	"NOTINUSE", 
	"UNSUPPORTED", 
	"UNTESTED", 
	"UNINITIATED", 
	"NORESULT", 
	"WARNING", 
	"TIMED_OUT", 
	"OTHER"
); 

use Getopt::Std;	# Std.pm is a standard perl module

getopts("r:p:v:s");

$op_valid = 1;
$match_reverse = 0;
$testcase_match = 0;

if ( $opt_p eq "*" || $opt_p eq ".*" ) {
	$opt_p = "";
}
else {
#	$opt_p =~ s/\*/.*/ ;
	$opt_p =~ s/\//\\\// ;
}
 
if ( $opt_r ) {
	$op_valid = 0;
	foreach $code (@result_codes) {
		if (( $opt_r eq $code )
		  || ( $opt_r eq "!$code" )) {
			$op_valid = 1;
			if ( substr($opt_r, 0, 1 ) eq "!" ) {
				$match_reverse = 1;
				$opt_r = substr($opt_r, 1);
			}
			break;
		}	   
	}
}

if ( $opt_v eq "all" ) {
	$opt_v = "[^|]*";
}

( $op_valid == 1 ) || die "\n$Progname: ERROR - unsupported result code, $opt_r.\nValid result codes are: @result_codes\n";

if ($#ARGV < 0) {
	out_usage;
	exit 1;
}

$FIRSTFILE = 0;
$comp_vers = 0;

foreach $i (0 .. $#ARGV) {

	$JNL_FILE = $ARGV[$i];

	open(JNL_FILE, $JNL_FILE) || die "\n$Progname: ERROR - Can't open journal file, $JNL_FILE.\n";

##  Flag for 1st line read ##
	$FIRSTLINE = 0;

##  Flag for baseline formatted file #
	$BASEFILE = 0;

	while (<JNL_FILE>) {
		split;
##  Check the first line to see if it's a baseline file ##
		if ($FIRSTLINE == 0) {
			++$FIRSTLINE;
##  Baseline file ?	 ##				  
			if ($_ =~ /^$Basekey/) {
				$BASEFILE = 1;
				if ($FIRSTFILE == 0) {
					++$FIRSTFILE;
##  set version # to compare against ##
					$comp_vers = $_[1];
					print $Basekey, " ", $comp_vers;
				}
				elsif ($_[1] ne $comp_vers) {
					warn "$Progname: WARNING - journal version number mismatch, possible format problems\n";
				}
				next;
			}
##  Not in baseline format, get the vers #   ##
			if (/^\Start\|/) {
##  Add a baseline tag to baseline file	  ##
				if ($FIRSTFILE == 0) {
					++$FIRSTFILE;
					$comp_vers = $_[6];
					print $Basekey, " ", $comp_vers;
				}
				elsif ($_[6] ne $comp_vers) {
					warn "$Progname: WARNING - journal version number mismatch, possible format compare problem\n";
				}
				next;
			}
######## First line didn't have a Start or a Baseline key #########
			die "$Progname: ERROR - $JNL_FILE is not a standard STF journal file\n";
		}
## if it's already a baseline file just add the results to the table ##
		if ($BASEFILE == 1){
			$id = shift @_;

			foreach $result(@_) {
				($resultname, $count) = split(/:/, $result);
				$count = 1 unless $count;
				if (( !$opt_r || is_code_match($resultname, $opt_r, $match_reverse))
				  && ( !$opt_p || is_testcase_match($id, $opt_p))) {
					$results{$id, $resultname} += $count;
					$total_results{$resultname} += $count;
				}
			}
			next;
		}
## New code for saving tbin and suitename to strip off of assertion name ##
		if (/^STF_ENV\|/) {
			if ($_[1]  eq "TBIN") {
				$tbin = $_[3];  ## set tbin
			}
			elsif ($_[1] eq "SUITE") {
				$suite = $_[3]; ## set suite name
			}
		}

		if (/^Test_Case_Start\|/) {
			$new_name = $_[2];
			$verbose_head = "";
			$verbose_buf = "";
			if ( !$opt_p || is_testcase_match($new_name, $opt_p)) {
				$testcase_match = 1;	
				if ( $opt_v ) {
					$verbose_head = "\n\n";
					$verbose_head = $verbose_head.$new_name." : (in ". $JNL_FILE. ")\n";
					$verbose_head = $verbose_head."----------------------------------------------------------------\n\n";
				}
			}
			else {
				$testcase_match = 0;
			}
			next;
		}
##  add to assertion
		if (/^Test_Case_End\|/) {
			$new_name = $_[2];
			if (( !$opt_r || is_code_match($_[4], $opt_r, $match_reverse))
			  && ( !$opt_p || is_testcase_match($new_name, $opt_p))) {
				if ( $verbose_buf ) {
					print $verbose_head;
					print $verbose_buf;
				}

				$results{$new_name, $_[4]} += 1;
				$total_results{$_[4]} += 1;
			}
			$verbose_head = "";
			$verbose_buf = "";
			next;
		}

##  add to sub-assertion
		if (/^Assertion_End\|/) {
			$new_name = $_[2];
			if (( !$opt_r || is_code_match($_[4], $opt_r, $match_reverse))
			  && ( !$opt_p || is_testcase_match($new_name, $opt_p))) {
				$results{$new_name, $_[4]} += 1;
				$total_results{$_[4]} += 1;
			}
			next;
		}

		if (/^Totals\|/) {
			shift @_;
			shift @_;
			# the 3rd field on... #
			$id = shift @_;
			shift @_;
			$new_name = &stripname($id);

			foreach $result(@_) {
				($resultname, $count) = split(/:/, $result);
				$count = 1 unless $count;
				if (( !$opt_r || is_code_match($resultname, $opt_r, $match_reverse))
				  && ( !$opt_p || is_testcase_match($new_name, $opt_p))) {
					$results{$new_name, $resultname} += $count;
					$total_results{$resultname} += $count;
				}
			}
			next;
		}
		if ( !$opt_v ) {
			next;
		}
		elsif (( $opt_v eq "[^|]*"  ) || /^$opt_v\|/) {
			if ( $testcase_match ) {
				$msg = $_;
				if ( $opt_s ) {
					$msg =~ s/^$opt_v\|\s/	/;
				}

				$verbose_buf = $verbose_buf.$msg;
			}
			next;
		}
	}
	close JNL_FILE;
}

foreach $id_array(sort keys %results) {
	($id, $resultname) = split(/\034/, $id_array);
	if ($id ne $prev_id) {
		print "\n", $id, " ";
		$prev_id = $id;
	}
	print " ", $resultname, ":", $results{$id, $resultname};
}

print "\n";
print "\n";
print "Result Total:\n";

foreach $resultname (sort keys(%total_results)) {
	print "\t", $resultname, ": ", $total_results{$resultname}, "\n";
}
	
