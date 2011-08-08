#!/usr/bin/ksh
#
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)ce_config_vars.ksh	1.2	07/11/09 SMI"
#

#
# Check that a set of variables has the values set
# Any required configurable variable defaults to
# "change_me_now" if no value is set
#

check_vars_set()
{
        # takes a list of variable names as input
        for var in $*; do
                value="`eval echo \\$$var`"
                if [ "$value" = "change_me_now" ] ||
			[ -z "$value" ]; then
                        echo "Variable $var is not set"
        		return 1
                fi
        done
        return 0
}

#
# Function ce_config_vars
#
# This function checks if the variables are configured as required.
#

function ce_config_vars
{
        print "checkenv: ce_config_vars($*)"

        errmsg="usage: ce_config_vars <hostname>"
        [ $# -lt 1 ] && abort $errmsg

        req_label="vars list"
        req_value=$1

        if [ $OPERATION == "dump" ]; then
                ce_config_vars_doc
                return $PASS
        fi

        if [ $OPERATION == "verify" ]; then
		check_vars_set $*
                if [ $? -ne 0 ]; then
                        echo "Please update the ${STF_SUITE}/config.vars."
                        exit 1
                else
                        result=PASS
                fi
        fi

        eval return \$$result

}


function ce_config_vars_doc
{
        cat >&1 << EOF

Check ce_config_vars $(TASK)
=================================
Description:
        check that a set of variables has the values set
Arguments:
        #1 -  takes a list of variable names as input
Requirement label (for this check):
        $req_label
Requirement value (for this check):
        $req_value
EOF
}

