#!/usr/bin/ksh
#
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)ce_interface_exist.ksh	1.1	07/07/02 SMI"
#

#
# Function ce_interface_exist
#
# This function checks whether the given test nic interface exists.
#

function ce_interface_exist
{
        print "checkenv: ce_interface_exist($*)"

        errmsg="usage: ce_interface_exist <TST_INT> <TST_NUM>"
        [ $# -ne 2 ] && abort $errmsg

        req_label="interface exists"
        req_value="$1$2"

        if [ $OPERATION == "dump" ]; then
                ce_interface_exist_doc
                return $PASS
        fi

	errmsg="The interface $1$2 dosn't exist on localhost"
        result=FAIL
        if [ $OPERATION == "verify" ]; then
                ifconfig "$1$2" >/dev/null 2>&1 && errmsg="" && result=PASS
        fi

        print_line $TASK "$req_label" "$req_value" "$result" "$errmsg"
        eval return \$$result
}

function ce_interface_exist_doc
{
        cat >&1 << EOF

Check ce_interface_exist $(TASK)
=================================
Description:
        check whether the given test nic interface exists using "ifconfig"
Arguments:
        #1 - the name of the nic interface
        #2 - the number of the interface instance
Requirement label (for this check):
        $req_label
Requirement value (for this check):
        $req_value
EOF
}

