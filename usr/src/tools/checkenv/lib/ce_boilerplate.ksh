
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

##############################################################

	***** !! BOILERPLATE CHECKENV FUNCTION !! *****

This file contains a boilerplate checkenv function.  It is 
recommended that you use this, in conjunction with an existing
checkenv function (that most closely resembled the function 
being developed).  

Places where you should substitue a value are deliniated with 
"<" and ">".  For example:
	
		function ce_<your_function_name>

Boilerplate comments vs. comments (those which explain the boilerplate
vs. those that are part of the boilerplate) are deliniated with 
"<<" and ">>".

##############################################################

#! /usr/bin/ksh  -p
#
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)ce_boilerplate.ksh	1.3	07/01/04 SMI"
#

# 
# Function ce_<check>
# 
# This function <provide a synopsis of what the check does>
#
function ce_<check>
{
	<< retrieve arguments passed >>
	typeset -l <some_arg>=${1}

	<< set overall result to PASS - this is the default >>
	result=PASS

	<< in this section you need to verify that the arguments are 
	   correct.  If there are problems call the "abort" function
	   with an error message >>

	# Check the argument and make sure it is as expected - abort
	# otherwise.
	#
	errmsg="<information about the expected arguments>"
	[[ $# -ne <# of args>  ]] && abort $errmsg

	[[ $1 != "<expected value #1>" && $1 != "<expected value #2>" ]] &&  abort $errmsg

	<< set the req_label and req_value.  req_label is what is printed
	   in the second field of the checkenv output.  It is a concise
	   description of what is being checked.  req_value is the value 
	   passed which indicates what the requirement is to check. >>

	req_label="<label for check>"
	req_value="<value of the requirement being checked>"


	<< do the dump operation.  Just call a function ce_<check> doc
	[[ $OPERATION = "dump" ]] && {
		ce_<check>_doc
		return $PASS
	}

	<< this condition codes the verification portion >>
	#
	# Verify that the system meets requirements - set result=[PASS|FAIL]
	#
	[[ $OPERATION = "verify" ]] && {
		
	  << add check here.  If check fails return FAIL.  If an error
	     is encountered then call "abort" to abort the test" >>
	}

	<< Print out standard output line.  You don't need to
	   change these lines >>

	print_line $TASK "$req_label" "$req_value" "$result"
	eval return \$$result
}

<< This is the function which is called when the dump operation is
   invoked. >>

function ce_ipv6_doc
{
	cat >&1 << EOF 

Check ce_<check> $(TASK)
============================
Description: 
	<description of the check>
Arguments: 
	#1 - <description of the first argument>
<< You don't need to change the following lines >>
Requirement label (for this check):   
	$req_label 
Requirement value (for this check): 
	$req_value
EOF
}
