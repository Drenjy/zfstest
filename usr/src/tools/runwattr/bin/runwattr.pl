#! /usr/perl5/bin/perl -Uw
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

require 5;
use strict;
use warnings qw( all );
no warnings qw( taint );

use Data::Dumper;

use English;
use Getopt::Long;
use Cwd;

use Sun::Solaris::Privilege qw( :ALL );

use vars qw( $FORCEPRIV );


sub trace_creds {
	my($trace_comment) = @_;
	print "creds ".$trace_comment.":\n";
	system("/usr/bin/zonename");
	system("/usr/bin/id");
	system("/usr/bin/pfexec", $FORCEPRIV, "-s", "A=zone", "-e",
		"/usr/bin/ppriv", $PID);
	print "\n";
}


sub trace_env {
	my($trace_comment) = @_;
	print "environment ".$trace_comment.":\n";
	system("/usr/bin/env");
	print "\n";
}


sub trace_exec {
	my($trace_comment, @exec_args) = @_;
	print "exec ".$trace_comment.":\n";
	print join(" ", @exec_args)."\n";
	print "\n";
}


sub setreuid {
	my($ruid, $euid) = @_;
	if ( $ruid ne "-1" ) {
		if ( $ruid !~ /^\d+$/ ) { $ruid = getpwnam($ruid); }
		$UID  = $ruid;
	}
	if ( $euid ne "-1" ) {
		if ( $euid !~ /^\d+$/ ) { $euid = getpwnam($euid); }
		$EUID = $euid;
	}
}


sub setregid {
	my($rgid, $egid) = @_;
	if ( $rgid ne "-1" ) {
		if ( $rgid !~ /^\d+$/ ) { $rgid = getgrnam($rgid); }
		$GID  = $rgid;
	}
	if ( $egid ne "-1" ) {
		if ( $egid !~ /^\d+$/ ) { $egid = getgrnam($egid); }
		$EGID = $egid;
	}
}


sub force_all_privs {
	my($pid) = @_;
	system("/usr/bin/pfexec", $FORCEPRIV, "-s", "A=zone", $pid);
}


sub shell_quote {

	# if any of the following are present:
	# backslash  backquote  dollar  doublequote
	# quote them with a backslash
	s#\134|\140|\044|\042#\\$&#g;

	# if any of the following are present:
	# ;  &  (  )  |  ^  <  >  newline  space  tab  singlequote
	# doublequote the whole string
	m#[;&()|^<>\n \t']# && do {
		$_ = '"'.$_.'"';
	};

	# doublequote null strings
	m#^$# && do {
		$_ = '""';
	};

}


sub usage {
	printf("usage: %s [-u uid] [-U uid] [-g gid] [-G gid] ".
		"[-p priv_mod ...] [-z zonename] [-i] [-e name=value ...] ".
		"[-D] [--] command [args ...]\n", $PROGRAM_NAME);
	exit(1);
}


# sub main
{

	my(
		$opt_forcepriv,
		$opt_debug,
		$opt_reuid, $opt_ruid,
		$opt_regid, $opt_rgid,
		$opt_zone,
		$opt_env_clear,
		@opt_env_vars,
		@opt_priv_mods,
		@cmd_args
	);

	Getopt::Long::Configure("no_ignore_case");
	GetOptions(
		"F=s"	=>  \$opt_forcepriv,
		"D"	=>  \$opt_debug,
		"u=s"   =>  \$opt_reuid,
		"U=s"   =>  \$opt_ruid,
		"g=s"   =>  \$opt_regid,
		"G=s"   =>  \$opt_rgid,
		"z=s"   =>  \$opt_zone,
		"i"     =>  \$opt_env_clear,
		"e=s@"  =>  \@opt_env_vars,
		"p=s@"  =>  \@opt_priv_mods,
	) or usage();

	@cmd_args = @ARGV;
	if ( $#cmd_args < 0 ) { usage(); }

	if ( defined $opt_debug ) {
		print "Debugging output enabled\n\n";
	}

	if ( defined $opt_debug ) {
		print "Command line options:\n";
		print Data::Dumper->Dump(
			[
				$opt_forcepriv,
				$opt_debug,
				$opt_reuid, $opt_ruid,
				$opt_regid, $opt_rgid,
				$opt_zone,
				\@opt_priv_mods,
				$opt_env_clear, \@opt_env_vars,
				\@cmd_args
			],
			[ qw(
				opt_forcepriv
				opt_debug
				opt_reuid opt_ruid
				opt_regid opt_rgid
				opt_zone
				*opt_priv_mods
				opt_env_clear *opt_env_vars
				*cmd_args
			) ]
		);
		print "\n";
	}

	# locate forcepriv binary
	if ( $opt_forcepriv ) {
		$FORCEPRIV = $opt_forcepriv;
	} else {
		if ( defined $ENV{'RUNWATTR_FORCEPRIV'} ) {
			$FORCEPRIV = $ENV{'RUNWATTR_FORCEPRIV'};
		} elsif ( -x "/var/tmp/SUNWstc-runwattr/forcepriv" ) {
			$FORCEPRIV = "/var/tmp/SUNWstc-runwattr/forcepriv";
		} elsif ( -x "/opt/SUNWstc-runwattr/lib/forcepriv" ) {
			$FORCEPRIV = "/opt/SUNWstc-runwattr/lib/forcepriv";
		} else {
			$FORCEPRIV = Cwd::realpath($PROGRAM_NAME);
			$FORCEPRIV =~ s#/bin/runwattr$#/lib/forcepriv#;
		}
	}
	if ( ! -x $FORCEPRIV ) {
		printf("runwattr: unable to locate forcepriv binary.\n");
		exit(1);
	}

	if ( defined $opt_debug ) {
		print "Using forcepriv binary: ".$FORCEPRIV."\n\n";
	}

	trace_creds("at invocation") if $opt_debug;
	trace_env("at invocation") if $opt_debug;


	# validate zone option
	if ( $opt_zone ) {
		my($orig_zone) = `/usr/bin/zonename`;
		chomp $orig_zone;
		if ( $orig_zone eq $opt_zone ) {
			# not trying to switch zones, so ignore the option
			undef $opt_zone;
		} else {
			# trying to switch zones
			# must be in global zone
			if ( $orig_zone ne "global" ) {
				printf("runwattr: '-z' cannot be used to ".
					"escape from a non-global zone.\n"); 
				exit(1);
			}
		}
	}


	# save original user/group ids

	my($orig_ruid, $orig_euid, $orig_rgid, $orig_egid);
	$orig_ruid = 0 + $UID;
	$orig_euid = 0 + $EUID;
	$orig_rgid = 0 + $GID;
	$orig_egid = 0 + $EGID;

	if ( $opt_debug ) {
		print Data::Dumper->Dump(
			[ $orig_ruid, $orig_euid, $orig_rgid, $orig_egid ],
			[ qw( orig_ruid orig_euid orig_rgid orig_egid ) ]
		);
		print "\n";
	}


	# determine new user/group ids

	my(
		$new_ruid, $new_euid,
		$new_rgid, $new_egid
	) = ("-", "-", "-", "-");

	if ( defined $opt_reuid ) {
		$new_ruid = $opt_reuid;
		$new_euid = $opt_reuid;
	}

	if ( defined $opt_ruid ) {
		$new_ruid = $opt_ruid;
	}

	if ( defined $opt_regid ) {
		$new_rgid = $opt_regid;
		$new_egid = $opt_regid;
	}

	if ( defined $opt_rgid ) {
		$new_rgid = $opt_rgid;
	}

	map
		{ if ( $_ eq "-" ) { $_ = -1; } }
		( $new_ruid, $new_euid, $new_rgid, $new_egid );

	if ( $opt_debug ) {
		print Data::Dumper->Dump(
			[ $new_ruid, $new_euid, $new_rgid, $new_egid ],
			[ qw( new_ruid new_euid new_rgid new_egid ) ]
		);
		print "\n";
	}


	# set new privileges

	my($new_priv_set, $new_priv_str);
	$new_priv_set = getppriv(PRIV_INHERITABLE);
	for my $priv_mod ( @opt_priv_mods ) {
		my($priv_mod_op, $priv_mod_str) = (
			substr($priv_mod, 0, 1),
			substr($priv_mod, 1)
		);
		my($priv_mod_set) = priv_str_to_set($priv_mod_str, ",");
		if ( $priv_mod_op eq "=" ) {
			$new_priv_set =
				priv_copyset($priv_mod_set);
		}
		if ( $priv_mod_op eq "+" ) {
			$new_priv_set =
				priv_union($priv_mod_set, $new_priv_set);
		}
		if ( $priv_mod_op eq "-" ) {
			$priv_mod_set = priv_inverse($priv_mod_set);
			$new_priv_set =
				priv_intersect($priv_mod_set, $new_priv_set);
		}
	}
	$new_priv_str = priv_set_to_str($new_priv_set, ",", PRIV_STR_PORT);


	# exec next command
	#  if switching zones, prepare new runwattr command and zlogin
	#  else, apply cred/env changes now and exec user command

	if ( defined $opt_zone ) {

		my(@zlogin_args) = ("/usr/sbin/zlogin", "-E", $opt_zone);

		if ( $new_euid eq "-1" ) { $new_euid = $orig_euid; }
		if ( $new_egid eq "-1" ) { $new_egid = $orig_egid; }
		if ( $new_ruid eq "-1" ) { $new_ruid = $orig_ruid; }
		if ( $new_rgid eq "-1" ) { $new_rgid = $orig_rgid; }

		my(@util_args) = ();
		push(@util_args, $PROGRAM_NAME);
		push(@util_args, "-F", $FORCEPRIV);
		push(@util_args, "-D") if defined $opt_debug;
		push(@util_args,
				"-u", $new_euid, "-g", $new_egid,
				"-U", $new_ruid, "-G", $new_rgid
		);
		push(@util_args, "-p", "=".$new_priv_str);
 		if ( defined $opt_env_clear ) {
			push(@util_args, "-i");
		} else {
			for my $env_name ( keys %ENV ) {
				my($env_var) = $env_name."=".$ENV{$env_name};
				push(@util_args, "-e", $env_var);
			}
		}
		for my $env_var ( @opt_env_vars ) {
			push(@util_args, "-e", $env_var);
		}

		map { shell_quote } @util_args;
		map { shell_quote } @cmd_args;

		my(@exec_args) = (@zlogin_args, @util_args, "--", @cmd_args);

		force_all_privs($PID);
		setreuid(0,0);
		setregid(0,0);

		trace_creds("to change zones") if $opt_debug;
		trace_exec("to change zones", @exec_args) if $opt_debug;

		exec(@exec_args);

	} else {

		force_all_privs($PID);

		setreuid($new_ruid, $new_euid);
		setregid($new_rgid, $new_egid);

		setppriv(PRIV_SET, PRIV_INHERITABLE, $new_priv_set);

		if ( defined $opt_env_clear ) {
			%ENV = ();
		}
		for my $env_var ( @opt_env_vars ) {
			my($env_name, $env_value) = split(/=/, $env_var, 2);
			$ENV{$env_name} = $env_value;
		}

		trace_creds("for user command") if $opt_debug;
		trace_env("for user command") if $opt_debug;
		trace_exec("for user command", @cmd_args) if $opt_debug;

		exec(@cmd_args);

	}

}


