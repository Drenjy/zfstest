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
# ident	"@(#)stf_jnl_spec.ksh	1.3	08/06/26 SMI"
#

#
# This is a shell script spec file generator that will extract the assertions,
# descriptions, and interfaces from a properly format shell script and
# place it in a spec file.
#

#-------------------

# Format:  Below is the required format to work with this program.
# It is important that the __stc_assertion__ header and footer; as well as,
# the keywords "ASSERTION:", "DESCRIPTION:", and "INTERFACE:" are placed with
# proper spacing displayed below.

# __stc_assertion__
# ASSERTION:
# test_001
# 
# DESCRIPTION:
# This will test the command to do something useful.  When the
# test is done it will be successful.
#
# INTERFACE:
# test_cmd(1)
#
# STRATEGY:
# 1) Call the test
# 2) Print out the results
#
# end __stc_assertion__ 

#-------------------

# Extract the assertion
function extract_assertion
{
	ASSERTION_NUM=`expr $ASSERTION_NUM + 1`
	x=`expr $DESC_NUM - $ASSERTION_NUM`
	s=`tail +$ASSERTION_NUM $1 | head -$x | cut -f 2 -d "#"`
	printf "%s\n" "ASSERTION: $s"
	return $?
}

# Extract the description
function extract_desc
{
	DESC_NUM=`expr $DESC_NUM + 1`
	x=`expr $INTERFACE_NUM - $DESC_NUM`
	s=`tail +$DESC_NUM $1 | head -$x | cut -f 2 -d "#" | fmt -w 65`
	printf "%s\n" "DESCRIPTION: $s"
	return $?
}

# Extract the interface
function extract_interface
{
	INTERFACE_NUM=`expr $INTERFACE_NUM + 1`
	x=`expr $STRATEGY_NUM - $INTERFACE_NUM`
	s=`tail +$INTERFACE_NUM $1 | head -$x | cut -f 2 -d "#"`
	printf "%s\n" "INTERFACE: $s"
	return $?
}

# Extract the entire stc_assertion section
function extract_all
{
	x=`expr $STC_END_NUM - $STC_NUM`
	tail +$STC_NUM $1 | head -$x
	return $?
}

# Usage statement
function usage
{
	echo "stf_jnl_spec -adiA -f <test script>"
	echo "\t-a : extract assertion"
	echo "\t-d : extract description"
	echo "\t-i : extract interface"
	echo "\t-A : extract the whole \"_stc_assertion_\" section"
	echo "\nLook inside this program for the assertion format requirements."
	exit 1;
}

#
# Main
#
while getopts Aadsif: flag
do
	case $flag in
		f) FILE="$OPTARG";;
		a) aflag=1;;
		d) dflag=1;;
		i) iflag=1;;
		A) allflag=1;;
		*) usage;;
	esac
done

if [ -z "$FILE" ] ; then
	echo "Must specify file\n"
	usage
fi

# Getting line values for assertion keywords.
STC_NUM=`grep -n "^# __stc_assertion__" $FILE| cut -f1 -d ":"`
STC_END_NUM=`grep -n "^# end __stc_assertion__" $FILE| cut -f1 -d ":"`
ASSERTION_NUM=`grep -n "^# ASSERTION" $FILE| cut -f1 -d ":"`
DESC_NUM=`grep -n "^# DESCRIPTION" $FILE| cut -f1 -d ":"`
STRATEGY_NUM=`grep -n "^# STRATEGY" $FILE| cut -f1 -d ":"`
INTERFACE_NUM=`grep -n "^# INTERFACE" $FILE| cut -f1 -d ":"`

if [ ! -z "$aflag" ] ; then
	extract_assertion $FILE
fi

if [ ! -z "$allflag" ] ; then
	extract_all $FILE
fi

if [ ! -z "$dflag" ] ; then
	extract_desc $FILE
fi

if [ ! -z "$iflag" ] ; then
	extract_interface $FILE
fi
