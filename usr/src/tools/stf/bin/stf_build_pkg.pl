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
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# This tool is designed to be run from within the STF build framework
# (via stf_build) and hence has dependencies on the following ENV variables:
#
#	STF_MACH
#	STF_SUITE
#	STF_SUITE_PROTO
#	STF_PKGARCHIVE
#	STF_SUITE_BUILD_MODES
#	STF_MACH_BUILD_MODES
#	STF_PKGMODE
#       STF_CONFIG_INPUTS
#	STF_TOOLS
#
# You can run this tool outside STF by setting these environment variables
# manually.  WARNING: You should only do this if you really know what you're
# doing.  Running via stf_build ensures that you don't accidentally build a
# package from an incomplete proto.
#

use Getopt::Std;	# Std.pm is a standard perl module

getopts("r");

#
# GLOBALS
#
my $TYPE_STCINFO = 1;
my $TYPE_PKGINFO = 2;

# Perl's localtime() function returns an array of values, of which
# the sixth element is the offset of the current year from 1900
my $current_year = (localtime)[5] + 1900;
my $COPYRIGHT = "\n".
   "Copyright $current_year Sun Microsystems, Inc.  All rights reserved.\n".
   "Use is subject to license terms.\n\n";

my $STAMP = $^T;

if ($ENV{'TMPDIR'} ne "") {
	$TMPDIR = $ENV{'TMPDIR'};
} else {
	$TMPDIR = "/tmp";
}
my %stcinfo_data;
my %pkginfo_data;
my $pkgarchive = "";
my $wspath = "";
my $proto_dir = "";
my $srcroot = "";
my $pkgmode = "";
my $is_a_suite = 0;
my @depend_entries = ("P\tSUNWcar\tCore Architecture, (Root)",
			"P\tSUNWkvm\tCore Architecture, (Kvm)",
			"P\tSUNWcsr\tCore Solaris, (Root)",
			"P\tSUNWcsu\tCore Solaris, (Usr)",
			"P\tSUNWcsd\tCore Solaris Devices",
			"P\tSUNWcsl\tCore Solaris Libraries");

#
# Grab values from the required env vars.  Exit if any of them are
# not set or have obviously invalid settings.
#
if ($ENV{'STF_MACH'} ne "") {
	$my_arch = $ENV{'STF_MACH'};
} else {
	print "STF_MACH is not set in the environment.  Please set to this ".
		"to the processor architecture of this machine\n";
	exit 1;
}

if ($ENV{'STF_SUITE'} ne "") {
	$srcroot = $ENV{'STF_SUITE'};
	if (! -e "$srcroot" || ! -e "$srcroot/STC.INFO") {
		print "ERROR: $srcroot is not a valid source root\n";
		print "Please set STF_SUITE to the source root of the tool or ".
			"suite to be packaged\n";
		exit 1;
	}
} else {
	print "STF_SUITE is not set in the environment.  Please set to this ".
		"to the source root of the tool or suite to be packaged\n";
	exit 1;
}

if ($ENV{'STF_SUITE_PROTO'} ne "") {
	$proto_dir = $ENV{'STF_SUITE_PROTO'};
	if (! $opt_r && ! -e "$proto_dir") {
		print "ERROR: $proto_dir is not a valid proto directory.\n";
		print "Please set STF_SUITE_PROTO to the proto root of the ".
			"tool or suite to be packaged\n";
		exit 1;
	}
} else {
	print "STF_SUITE_PROTO is not set in the environment.  Please set ".
		"this to the source root of the tool or suite to be packaged\n";
	exit 1;
}

if ($ENV{'STF_PKGARCHIVE'} ne "") {
	$pkgarchive = "$ENV{'STF_PKGARCHIVE'}/$my_arch";
} else {
	print "STF_PKGARCHIVE is not set in the environment.  Please set ".
		"this to the location where the generated package should be ".
		"spooled\n";
	exit 1;
}

if ($ENV{'STF_SUITE_BUILD_MODES'} ne "") {
	@all_build_modes = split(/\ /, $ENV{'STF_SUITE_BUILD_MODES'});
} else {
	print "STF_SUITE_BUILD_MODES is not set in the environment.  Please ".
		"set this to the list of all possible build modes for this ".
		"suite or tool";
	exit 1;
}

if ($ENV{'STF_MACH_BUILD_MODES'} ne "") {
	@my_build_modes = split(/\ /, $ENV{'STF_MACH_BUILD_MODES'});
} else {
	print "WARNING: STF_MACH_BUILD_MODES is not set in the environment.\n".
		"This usually means that there exist no binaries to be ".
		"packaged that correspond\n".
		"to the current machine's processor architecture ($my_arch).\n".
		"If you know this to be incorrect, please set ".
		"STF_MACH_BUILD_MODES to the\n".
		"list of all build modes that apply to architecture ".
		"'$my_arch', and try again.\n";
	exit 0;
}

my @my_bin_locations = @my_build_modes;
my $config_inputs = "";
if ($ENV{'STF_CONFIG_INPUTS'} ne "") {
        $config_inputs = $ENV{'STF_CONFIG_INPUTS'};
} else {
        print "STF_CONFIG_INPUTS is not set in the environment.  Please ".
            "set this to the list of all possible config input for this ".
            "suite or tool";
        exit 1;
}

my $configlookup = "";

if ($ENV{'STF_TOOLS'} ne "") {
	$configlookup = $ENV{'STF_TOOLS'} . '/build/stf_configlookupbinary';
} else {
	print "STF_TOOLS is not set in the environment. Please ".
	    "set this to the location of STF";
	exit 1;
}

foreach $e (@my_bin_locations) {
        chomp($e = `$configlookup BinaryLocation $e $config_inputs`);
}

my @all_bin_locations = @all_build_modes;
foreach $e (@all_bin_locations) {
        chomp($e = `$configlookup BinaryLocation $e $config_inputs`);
}

if ($ENV{'STF_PKGMODE'} ne "") {
	$pkgmode = $ENV{'STF_PKGMODE'};
} else {
	print "STF_PKGMODE is not set in the environment.  Please set ".
		"this to the file mode creation mask of the tool or suite to be packaged\n";
	exit 1;
}

if ( !$opt_r ) {
	print "PROTO ROOT:   $proto_dir\n";
	print "SOURCE ROOT:  $srcroot\n";
	print "PKGARCHIVE:   $pkgarchive\n";
	print "PKGMODE:      $pkgmode\n";
	print "MACH BUILD MODES:  ", join(" ", @my_build_modes), "\n";
	print "SUITE BUILD MODES: ", join(" ", @all_build_modes), "\n";
}

#
# Populate pkginfo hash with default data, plus data
# mined from the STC.INFO file
#
# Then if the user supplied a pkginfo file with any overrides,
# we merge those values in.
#
&read_info("$srcroot/STC.INFO", $TYPE_STCINFO);
&populate_pkginfo_data;
if (-e "$srcroot/pkgdef/pkginfo") {
	&read_info("$srcroot/pkgdef/pkginfo", $TYPE_PKGINFO);
}

if ( $opt_r ) {
	&remove_package;
}
else {

	&build_pkginfo;

	&build_depend;

	&build_copyright;

	&build_prototype;

	&build_pkg;
}

&cleanup;

exit 0;


###############################################################################
# SUBROUTINES
###############################################################################

#####################################################################
# arg1: path to STC.INFO or pkginfo file
# arg2: type of file being read
#
# returns: void
#
# reads name/value pairs from specifcied file and encodes them in
# the specified hash
#####################################################################
sub read_info
{
	my $ftype = $_[1];

	open(INFO, "$_[0]")
	  || &fatal_error("ERROR: Unable to open $_[0]\n");

	print "Reading STC data from $_[0]\n";
	while (<INFO>) {
		my $line = $_;

		#
		# skip comments
		#
		next if ($line =~ /^\#/);
		#
		# skip lines that begin w\ whitespace
		#
		next if ($line =~ /^\s+/);

		my ($key, $value) = split(/=/, $line);
		chomp($value);

		if ($ftype == $TYPE_STCINFO) {
			$stcinfo_data{$key} = $value;
		} elsif ($ftype == $TYPE_PKGINFO) {
			$pkginfo_data{$key} = $value;
		}
	}

	close(INFO);
}


###############################################################
# ARGS: none
#
# returns: void
#
# populates the pkginfo_data hash with a set of default values
# for all of the name/value pairs that will be put in the
# pkginfo(4) file.
#
# Then we override those values with whatever may be in the
# stcinfo_data hash
###############################################################
sub populate_pkginfo_data
{
	#
	# We want to use the name of the suite or tool specified in STC_NAME
	# as the 'name' of the package
	if ($stcinfo_data{'STC_NAME'} ne "") {
		$pkginfo_data{'NAME'} = $stcinfo_data{'STC_NAME'};
		$pkginfo_data{'DESC'} = $stcinfo_data{'STC_NAME'};	
		# "eat up" all '"' characters from STC_NAME
		($name = $stcinfo_data{'STC_NAME'}) =~ s/\"//g;
	} else {
		print "FATAL ERROR: STC.INFO does not contain an STC_NAME ".
			"entry.\n";
		&cleanup;
		exit 1; 
	}
	
	# Use STC_SYNOPSIS for the package DESC, if possible
	if ($stcinfo_data{'STC_SYNOPSIS'} ne "") {
		($pkginfo_data{'DESC'} = $stcinfo_data{'STC_SYNOPSIS'})
			=~ s/\"//g;
	}

	#
	# STC_NAME may have characters not suitable for package names.
	# Substitute for characters that aren't allowed in package
	# names with dashes "-"
	#
	$name =~ tr!_@ ^#%+~=:,/!-!s;

	chomp($pkg_rev = `date \'+%m.%d.%y,%H:%M:%S\'`);
        chomp($pkg_host = `uname -n`);
        chomp($pkg_date = `date +\%Y\%m\%d\%H\%M\%S`);

	$pkginfo_data{'PKG'} = "SUNWstc-$name";
	$pkginfo_data{'NAME'} = "$name";
	$pkginfo_data{'BASEDIR'} = "/opt/SUNWstc-$name";
	$pkginfo_data{'CLASSES'} = "none";
	$pkginfo_data{'VENDOR'} = "\"Sun Microsystems, Inc.\"";
	$pkginfo_data{'SUNW_PRODNAME'} = "\"Solaris Test Collection\"";
	$pkginfo_data{'CATEGORY'} = "system";

	$pkginfo_data{'ARCH'} = $my_arch;
        $pkginfo_data{'PSTAMP'} = $pkg_host . $pkg_date;

	if ($stcinfo_data{'STC_CONTACT'} ne "") {
		$pkginfo_data{'HOTLINE'} = $stcinfo_data{'STC_CONTACT'};
	} else {
		print "FATAL ERROR: STC.INFO does not contain an STC_CONTACT ".
			"entry.\n";
		&cleanup;
		exit 1; 
	}

	if ($stcinfo_data{'STC_VERSION'} ne "") {
		$pkginfo_data{'VERSION'} 
			= "$stcinfo_data{'STC_VERSION'},REV=$pkg_rev";
	} else {
		print "FATAL ERROR: STC.INFO does not contain an STC_VERSION ".
			"entry.\n";
		&cleanup;
		exit 1; 
	}
}

##########################################################
# args: none
#
# returns: void
#
# writes out pkginfo file using data in pkginfo_data hash
##########################################################
sub build_pkginfo
{
	open(PKGINFO, ">$TMPDIR/pkginfo.$STAMP")
	  || &fatal_error("ERROR: Unable to open $TMPDIR/pkginfo.$STAMP ".
	  		"for writing\n");

	foreach (keys(%pkginfo_data)) {
		my $key = $_;
		my $value = $pkginfo_data{$key};
		print PKGINFO "$key=$value\n";
	}

	close(PKGINFO);
}

##################################################################
# args: none
#
# returns: void
#
# looks for a suite-local depend file and merges it with the
# depend_entries array.  Then writes out contents of depend array
# to the depend(4) file
##################################################################
sub build_depend
{
	#
	# If it's a test suite, then we'll also include a dependency
	# on SUNWstc-stf
	#
	if ($is_a_suite) {
		push(@depend_entries, "P\tSUNWstc-stf Solaris Test Framework");
	}
	
	if (-e "$srcroot/pkgdef/depend") {
		open(DEPEND_IN, "$srcroot/pkgdef/depend")
		  || &fatal_error("ERROR: Unable to open ".
		  	"$srcroot/pkgdef/depend\n");

		print "Reading test/tool-supplied depend file\n";
		while(<DEPEND_IN>) {
			my $entry = $_;
			chomp $entry;
			if ($entry =~ /^(P|I|R)\s+(\S+)/) {
				my $tag = $1;
				my $pkg = $2;
				if (grep(/^$tag\s+$pkg/, @depend_entries) == 0) {
					push(@depend_entries, $entry);
				}
			}
		}

		close(DEPEND_IN);
	}
	open (DEPEND_OUT, ">$TMPDIR/depend.$STAMP")
	  || &fatal_error("ERROR: Unable to open $TMPDIR/depend.$STAMP ".
	  		"for writing\n");

	foreach(@depend_entries) {
		print DEPEND_OUT "$_\n";
	}

	close(DEPEND_OUT);
}

#####################################################
# args: none
#
# returns: void
#
# writes contents of $COPYRIGHT to copyright(4) file
#####################################################
sub build_copyright
{
	open(COPY, ">$TMPDIR/copyright.$STAMP")
	  || &fatal_error("ERROR: Unable to open ".
	  		"$TMPDIR/copyright.$STAMP\n");

	my $cprtfile = "$srcroot/pkgdef/copyright";
	if (! -e "$cprtfile") {
		print "No custom copyright file found.  ";
		print "Generating default copyright.\n";

		if ($srcroot =~ m#/usr/src/#g) {
			$cprtfile = $ENV{'STF_TOOLS'} . '/etc/CDDL';
			print "Building open source package.  Using CDDL.";
			print "($cprtfile)\n";
		} else {
			print "Building closed package\n";
		}
	}

	if (open(CPRT, "<$cprtfile")) {
		while (<CPRT>) {
			my $line = $_;
			print COPY $line;
		}
		close CPRT;
	} else {
		print "Cannot open $cprtfile: $!\n";
	}

	print COPY $COPYRIGHT;

	close(COPY);
}

###################################################################
# args: none
#
# returns: void
#
# Builds a list of files to be included in the
# package, then combines this list with a list of package includes
# and writes out the prototype(4) file
###################################################################
sub build_prototype
{
	print "Determine applicable buildmodes for this architecture\n";

	print "Building package prototype file\n";
	&process_dir($proto_dir, "");

	open (PROTO_FILES, ">$TMPDIR/proto_files.$STAMP")
	  || &fatal_error("Unable to open file for writing: ".
	  		"$TMPDIR/proto_files.$STAMP\n");

	foreach (@proto_files) {
		print PROTO_FILES "$_\n";
	}
	close (PROTO_FILES);

	my $pkgcmd = "(cd $proto_dir; cat $TMPDIR/proto_files.$STAMP ".
		"| pkgproto > $TMPDIR/prototype1.$STAMP)";
	my $exit_status = system("$pkgcmd");
	if ($exit_status != 0) {
		$exit_status = $exit_status / 256;
		print "Command failed: $pkgcmd\n";
		print "Existed with status $exit_status\n";
		&cleanup;
		exit 1;
	}

	open(PROTO_IN, "$TMPDIR/prototype1.$STAMP")
	  || &fatal_error("Unable to open $TMPDIR/prototype1.$STAMP for ".
	  		"reading\n");

	open(PROTO_OUT, ">$TMPDIR/prototype2.$STAMP")
	  || &fatal_error("ERROR: Unable to open $TMPDIR/prototype2.$STAMP ".
	  		"for writing\n");

	while (<PROTO_IN>) {
		my @fields = split(/\ /, $_);
		print PROTO_OUT "$fields[0] $fields[1] $fields[2] $fields[3] ".
			"root root\n";
	}

	close(PROTO_IN);

	print PROTO_OUT "i pkginfo=$TMPDIR/pkginfo.$STAMP\n";
	print PROTO_OUT "i depend=$TMPDIR/depend.$STAMP\n";
	print PROTO_OUT "i copyright=$TMPDIR/copyright.$STAMP\n";

	#
	# Check for suite-local install/remove scripts and include those
	# in the package if we find them
	#
	if (-e "$srcroot/pkgdef/preinstall") {
		print PROTO_OUT "i preinstall=$srcroot/pkgdef/preinstall\n";
	}
	if (-e "$srcroot/pkgdef/postinstall") {
		print PROTO_OUT "i postinstall=$srcroot/pkgdef/postinstall\n";
	}
	if (-e "$srcroot/pkgdef/preremove") {
		print PROTO_OUT "i preremove=$srcroot/pkgdef/preremove\n";
	}
	
	close(PROTO_OUT);
}

##################################################################
# arg1: full pathname of directory to process
# arg2: internal use 
#
# returns: void
#
# recursively descends proto area to build the global array
# @proto_files with the list of files that should be included in
# the package
##################################################################
sub process_dir
{
	my $dir = $_[0];
	my $relative_root = $_[1];

	chomp($basename = `basename $dir`);
	$recursion_level++;

	#
	# If directory is for a mode that we're not interested in, then
	# we return immediately.
	#
	if (&seq_search($basename, @all_bin_locations)) {
		if (! &seq_search($basename, @my_bin_locations)) {
			print "Skipping $dir\n";
			$recursion_level--;
			return;
		}
	}	
	print "SCANNING $dir\n";
	lstat("$dir");
	#
	# process file if it exists, is a directory and not a symbolic link
	#
	if( ( -e _ ) && ( -d _ ) && ! ( -l _ )) {
		opendir(PROTO_DIR, "$dir")
		  || &fatal_error("Unable to open directory: $dir\n");
			  
		my @allfiles = readdir(PROTO_DIR);
		closedir(PROTO_DIR);
			
		for(@allfiles) {
			my $file = $_;
				
			next if $file eq '.';
			next if $file eq '..';
			next if $file eq "SCCS";
			
			stat("$dir/$file");
			if( -d _ ) {
				if ($relative_root eq "") {
					&process_dir("$dir/$file", "$file");
					push(@proto_files, "$file");
				} else {
					&process_dir("$dir/$file",
						"$relative_root/$file");
					push(@proto_files,
						"$relative_root/$file");
				}

			} else {
				if ($relative_root eq "") {
					push(@proto_files, "$file");
				} else {
					push(@proto_files,
						"$relative_root/$file");
				}
			}
		}
	} else {
		print "Skipping $dir\n";
	}
	$recursion_level--;
}

##################################################################
# args: none
#
# returns: void
#
# calls pkgmk(1) on pkgdef files that we generated and spools the
# package to $pkgarchive
##################################################################
sub build_pkg
{
	my $pkgname = $pkginfo_data{'PKG'};

	print "Building package $pkgname\n";
	my $exit_status = system("umask $pkgmode && mkdir -p $pkgarchive");
	if ($exit_status != 0) {
		$exit_status = $exit_status / 256;
		&fatal_error(
			"Command failed: umask $pkgmode && mkdir -p $pkgarchive\n".
			"Existed with status $exit_status\n"
			);
	}

	my $buildcmd = "(umask $pkgmode && ".
		"pkgmk -o -f $TMPDIR/prototype2.$STAMP -d ".
		"$pkgarchive -r $proto_dir)";
	$exit_status = system($buildcmd);
	if ($exit_status != 0) {
		$exit_status = $exit_status / 256;
		&fatal_error(
			"Command failed: $buildcmd\nExisted with status ".
			"$exit_status\n"
			);
	}
}

##################################
# arg1 = key to search array for
# arg2 = array to be searched
#
# returns: 1, if found
#	   0, otherwise
##################################
sub seq_search
{
 	my $key = shift(@_);
	my $element = "";

	foreach (@_) {
		$element = $_;
		if ($element eq $key) {
			return (1);
		}
	}
        return (0)
}

##################################
# arg1 = error message
#
# returns: void
###################################
sub fatal_error
{
	&cleanup;
	die "$msg";
}

##################################################################
# args: none
#
# returns: void
#
# clean up any temp files we created
##################################################################
sub cleanup
{
	`rm -f $TMPDIR/pkginfo.$STAMP`;
	`rm -f $TMPDIR/depend.$STAMP`;
	`rm -f $TMPDIR/copyright.$STAMP`;
	`rm -f $TMPDIR/prototype1.$STAMP`;
	`rm -f $TMPDIR/prototype2.$STAMP`;
	`rm -f $TMPDIR/proto_files.$STAMP`;
}

#################################################################
# args: none
#
# returns: void
#
# clean up package directory
#################################################################
sub remove_package
{
	my $dir = "$pkgarchive/$pkginfo_data{'PKG'}"; 
	print "Remove package archive:   $dir\n";
	`rm -rf $dir`;
}

