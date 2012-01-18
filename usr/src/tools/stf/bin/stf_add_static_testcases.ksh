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
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

. ${STF_TOOLS}/include/stf_common.kshlib

function fail
{
	print -u2 "Fatal error creating testcases!"
	exit 1
}

#
# This script searches in the current directory for any statically
# defined test cases and generates the appropriate test case list
# during the configure process, using publicly defined interfaces.
# The STF_*_TESTCASES variables are defined by the STF.  In creating
# your own dynamic test case generator, follow the example syntax for
# stf_addassert as indicated below.
#
# In our static cases below, the testcase name will be the same
# as the test command, by virtue of the nature of statically defined
# assertions.  See comments at the end of this file for an example
# of dynamically defined testcases.  Note that the nominalizespaces
# function removes gratuitous whitespace to ensure a variable is
# defined as something actionable
#

#
# Define root test cases, as indicated by the Makefile in the current
# configuration directory
#
STF_ROOT_TESTCASES=$(nominalizespaces $STF_ROOT_TESTCASES)
if (( ${#STF_ROOT_TESTCASES} )); then
	print "Creating static root testcases in ${reldir}...\n"
	for testcase in $STF_ROOT_TESTCASES; do
		stf_addassert -u root -t "$testcase" \
		    -c "$testcase" || fail
	done
fi

#
# Define user test cases, as indicated by the Makefile in the current
# configuration directory
#
STF_USER_TESTCASES=$(nominalizespaces $STF_USER_TESTCASES)
if (( ${#STF_USER_TESTCASES} )); then
	print "Creating static user testcases in ${reldir}...\n"
	for testcase in $STF_USER_TESTCASES; do
		stf_addassert -t "$testcase" -c "$testcase" || fail
	done
fi

#
# More notes on creating a dynamic test case generator...
#
# Suppose that you have a configuration file called /var/tmp/mytest.cfg
# and that the dynamic test cases to be run as root are based on the
# values of var1, var2, var3, and foo1, foo2, foo3.  Each test case
# will be run by a program called "runme".  A simple generator
# could be constructed as follows:
#
# - Define STF_TESTCASES_GEN=mkassert_root in your Makefile for
#   that test subdirectory
#
# - Create a mkassert_root.ksh testcase generator like the following:
# 
#  ----------------------------------------------------------------------
#  #!/bin/ksh -p
#  # source the config file to determine our config
#
#  . /var/tmp/mytest.cfg
#
#  for var in var1 var2 var3; do
#  	for var2 in foo1 foo2 foo3; do
#  		echo "gencomment: adding test $var-$var2..."
#  		stf_addassert -u root -t "$var-$var2" -c runme $var:$var2
#		if [[ $? -ne 0 ]]; then
#		    echo "Failure adding test case $var-$var2, aborting." 2>&1
#		    exit 1
#		fi 
#  	done
#  done
#  ----------------------------------------------------------------------
# 
# - In this example, runme is either a program defined as an STF_EXECUTABLE
#   in the current test suite, some program in the test suite's bin path,
#   or a program on the system.  Absolute path can be specified if needed.
#   The example above says "Define a root-executed test called $var-$var2
#   with test command "runme $var-$var2".  These tests are defined at configure
#   time, so configuration and test cases can change based on user input
#   with no compilation changes.
#
