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

package		jnl;
require		Exporter;
@ISA	=	qw(Exporter);

@EXPORT	=	qw(jnl_PASS
		jnl_FAIL
		jnl_UNRESOLVED
		jnl_NOTINUSE
		jnl_UNSUPPORTED
		jnl_UNTESTED
		jnl_UNINITIATED
		jnl_NORESULT
		jnl_WARNING
		jnl_TIMED_OUT
		jnl_OTHER
		jnl_rc2string
		jnl_print
		jnl_LOG
		jnl_ASSERTION
		jnl_ASSERT
		jnl_RESULT
		jnl_DIAGNOSTIC
		jnl_PROGRESS
		jnl_VERBOSE
		jnl_STACK
		jnl_ENCYCLOPEDIC
		jnl_OPERATION
		jnl_EXPECTED
		jnl_ERROR
		jnl_ACTION
		jnl_dl_fetch
		jnl_dl_check
		jnlDL_ASSERTION
		jnlDL_RESULT
		jnlDL_DIAGNOSTIC
		jnlDL_PROGRESS
		jnlDL_VERBOSE
		jnlDL_STACK
		jnlDL_ENCYCLOPEDIC
		);

@EXPORT_OK	=	@EXPORT;

require 5.005;
use strict;
use diagnostics;
use locale;

BEGIN { 
	# set all result codes
	$jnl::PASS=0;
	$jnl::FAIL=1;
	$jnl::UNRESOLVED=2;
	$jnl::NOTINUSE=3;
	$jnl::UNSUPPORTED=4;
	$jnl::UNTESTED=5;
	$jnl::UNINITIATED=6;
	$jnl::NORESULT=7;
	$jnl::WARNING=8;
	$jnl::TIMED_OUT=9;
	$jnl::OTHER=10;

	# create hash of result code to string
	%jnl::rc2string = (
		$jnl::PASS => "PASS",
		$jnl::FAIL => "FAIL",
		$jnl::UNRESOLVED => "UNRESOLVED",
		$jnl::NOTINUSE => "NOTINUSE",
		$jnl::UNSUPPORTED => "UNSUPPORTED",
		$jnl::UNTESTED => "UNTESTED",
		$jnl::UNINITIATED => "UNINITIATED",
		$jnl::NORESULT => "NORESULT",
		$jnl::WARNING => "WARNING",
		$jnl::TIMED_OUT => "TIMED_OUT",
		$jnl::OTHER => "OTHER"
	);

	# set all the detail levels

	$jnl::DL_ASSERTION = 0;
	$jnl::DL_RESULT = 1;
	$jnl::DL_DIAGNOSTIC = 10;
	$jnl::DL_PROGRESS = 100;
	$jnl::DL_VERBOSE = 1000;
	$jnl::DL_STACK = 10000;
	$jnl::DL_ENCYCLOPEDIC = 100000;

	# create a hash to map detail levels to strings

	%jnl::DL_STRING = (
		$jnl::DL_ASSERTION => "Assertion",
		$jnl::DL_RESULT => "Result",
		$jnl::DL_DIAGNOSTIC => "Diagnostic",
		$jnl::DL_PROGRESS => "Progress",
		$jnl::DL_VERBOSE => "Verbose",
		$jnl::DL_STACK => "Stack",
		$jnl::DL_ENCYCLOPEDIC => "Encyclopedic"
	);

	# create a hash to map strings to detail levels

	%jnl::DL_VALUE = (
		"ASSERTION" => $jnl::DL_ASSERTION,
		"RESULT" => $jnl::DL_RESULT,
		"DIAGNOSTIC" => $jnl::DL_DIAGNOSTIC,
		"PROGRESS" => $jnl::DL_PROGRESS,
		"VERBOSE" => $jnl::DL_VERBOSE,
		"STACK" => $jnl::DL_STACK,
		"ENCYCLOPEDIC" => $jnl::DL_ENCYCLOPEDIC
	);

	# read the environment variable TJNL_DETAIL to set the
	# detail level

	my $env_dl = $ENV{"TJNL_DETAIL"};
	my $dl;

	if (defined($env_dl)) {
		$dl = uc($env_dl);
		$jnl::DL = $jnl::DL_VALUE{$dl};
	}	

	if (!defined($jnl::DL)) {
		$jnl::DL = $jnl::DL_PROGRESS;
	}
}

sub TC_PASS() {
	return $jnl::PASS;
}

sub jnl_FAIL() {
	return $jnl::FAIL;
}

sub jnl_UNRESOLVED() {
	return $jnl::UNRESOLVED;
}

sub jnl_NOTINUSE() {
	return $jnl::NOTINUSE;
}

sub jnl_UNSUPPORTED() {
	return $jnl::UNSUPPORTED
}

sub jnl_UNTESTED() {
	return $jnl::UNTESTED
}

sub jnl_UNINITIATED() {
	return $jnl::UNINITIATED;
}

sub jnl_NORESULT() {
	return $jnl::NORESULT;
}

sub jnl_WARNING() {
	return $jnl::WARNING;
}

sub jnl_TIMED_OUT() {
	return $jnl::TIMED_OUT;
}

sub jnl_OTHER() {
	return $jnl::OTHER;
}

sub jnl_rc2string($){
	my $string = $jnl::rc2string{$_[0]};
	if (!defined($string)) {
		$string = "UNKNOWN"
	}
	return $string;
}

sub jnl_PASS() {
	return $jnl::PASS;
}

sub getstack() {
	my @stack;
	my $stackline;

	my $i = 1;
	for (;;) {
		my @frame = caller($i);

		last if (!@frame);

		my ($package,
			$filename,
			$line,
			$subroutine,
			$hasargs,
			$wantarray,
			$evaltext,
			$is_require) = @frame;

		($filename) = $filename =~ /([^\/]*)$/;
		$stackline = "$subroutine - file: $filename, line: $line";

		push @stack, ($stackline);
		$i++;
	}

	return @stack;
}

sub getfileline() {
	my @frame = caller(2);

	my ($package,
		$filename,
		$line,
		$subroutine,
		$hasargs,
		$wantarray,
		$evaltext,
		$is_require) = @frame;

	($filename) = $filename =~ /([^\/]*)$/;

	return ($filename, $line);
}

sub jnl_dl_check($) {
	if ($_[0] <= $jnl::DL) {
		return 1;
	} else {
		return 0;
	}
}

sub jnl_dl_fetch() {
	return $jnl::DL;
}

sub jnlDL_ASSERTION() {
	return $jnl::DL_ASSERTION;
}

sub jnlDL_RESULT() {
	return $jnl::DL_RESULT;
}

sub jnlDL_DIAGNOSTIC() {
	return $jnl::DL_DIAGNOSTIC;
}

sub jnlDL_PROGRESS() {
	return $jnl::DL_PROGRESS;
}

sub jnlDL_VERBOSE() {
	return $jnl::DL_VERBOSE;
}

sub jnlDL_STACK() {
	return $jnl::DL_STACK;
}

sub jnlDL_ENCYCLOPEDIC() {
	return $jnl::DL_ENCYCLOPEDIC;
}

sub jnl_LOG($@) {
	my $dl = shift;
	my $logline;

	if (jnl_dl_check($dl)) {
		my ($file, $line) = getfileline();
		print `stf_jnl_msg "[ - $jnl::DL_STRING{$dl} (file: $file, line $line) - ]"`;
		if (jnl_dl_check(jnlDL_STACK)) {
			print `stf_jnl_msg "Stack:"`;
			my @stack = getstack();
			shift @stack;
			my $frame;

			for $frame (@stack) {
				print `stf_jnl_msg "- $frame"`;
			}
		}	
		my $entry = join("", @_);
		my @lines = split(/\n/, $entry);
        
		for $logline (@lines) {
			print `stf_jnl_msg "$logline"`;
		}
	}
	print `stf_jnl_msg " "`;
	return 0;	
}

sub jnl_ASSERTION(@) {
	my ($file, $line) = getfileline();

	my $assert;
	my $interfaces;
	my @assertlines;
	my @interfacelines;

	if (scalar(@_) == 0) {
		my $specfile = $file;
		$specfile =~ s/\.pl$//;
		$specfile = "$specfile.spec";
		print "specfile: $specfile\n";
		print "file: $file\n";

		open(SPEC, $specfile) or do {
			@assertlines = ("Unable to open spec file");
			@interfacelines = ("Unable to open spec file");
		};
		close(SPEC);
		my @specfile = <SPEC> or do {
			@assertlines = ("Unable to read spec file");
			@interfacelines = ("Unable to read spec file")
		};
	} else {
		$assert = shift;
		$interfaces = shift;
		@assertlines = split(/\n/, $assert);
		@interfacelines = split(/\n/, $interfaces);
	}

	map { $_ = "- $_\n" } @assertlines;
	map { $_ = "- $_\n" } @interfacelines;

	$assert = join("", @assertlines);
	$interfaces = join("", @interfacelines);
	return (jnl_LOG(jnlDL_ASSERTION,
		"ASSERTION:\n".
		"- $file\n".
		"DESCRIPTION:\n".
		"$assert".
		"INTERFACES:\n".
		"$interfaces"));
}

sub jnl_ASSERT(@) {
	my $number;
	my $assert;
	my @numberlines;
	my @assertlines;

	$number = shift;
	$assert = shift;

	@numberlines = split(/\n/, $number);
	@assertlines = split(/\n/, $assert);

	map { $_ = "- $_\n" } @numberlines;
	map { $_ = "- $_\n" } @assertlines;

	$number = join("", @numberlines);
	$assert = join("", @assertlines);
	return (jnl_LOG(jnlDL_ASSERTION,
		"ASSERTION ID:\n".
		"$number".
		"DESCRIPTION:\n".
		"$assert"));
}

sub jnl_RESULT($) {
	return (jnl_LOG(jnlDL_RESULT,
		"RESULT: ", jnl_rc2string($_[0])));
}

sub jnl_DIAGNOSTIC(@) {
	my ($operation, $expected, $error, $action) = @_;
	return (jnl_LOG(jnlDL_DIAGNOSTIC, @_));
}

sub jnl_PROGRESS(@) {
	return (jnl_LOG(jnlDL_PROGRESS, @_));
}

sub jnl_print(@) {
	return (jnl_LOG(jnlDL_PROGRESS, @_));
}

sub jnl_VERBOSE(@) {
	return (jnl_LOG(jnlDL_VERBOSE, @_));
}

sub jnl_STACK(@) {
	return (jnl_LOG(jnlDL_STACK, @_));
}

sub jnl_ENCYCLOPEDIC(@) {
	return (jnl_LOG(jnlDL_ENCYCLOPEDIC, @_));
}

sub jnl_OPERATION(@) {
	my $lines = join("", @_);
        my @lines = split(/\n/, $lines);

	map { $_ = "- $_\n" } @lines;
	$lines = join("", @lines);
	return "Operation:\n$lines";
}

sub jnl_EXPECTED(@) {
	my $lines = join("", @_);
	my @lines = split(/\n/, $lines);

	map { $_ = "- $_\n" } @lines;
	$lines = join("", @lines);
	return "Expected:\n$lines";
}

sub jnl_ERROR(@) {
	my $lines = join("", @_);
	my @lines = split(/\n/, $lines);

	map { $_ = "- $_\n" } @lines;
	$lines = join("", @lines);
	return "Error:\n$lines";
}

sub jnl_ACTION(@) {
	my $lines = join("", @_);
	my @lines = split(/\n/, $lines);

	map { $_ = "- $_\n" } @lines;
	$lines = join("", @lines);
	return "Action:\n$lines";
}
