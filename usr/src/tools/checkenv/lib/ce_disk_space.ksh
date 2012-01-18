#
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#

#
# Check the remote host is alive and rsh reachable
# $1 remote hostname
#
check_host_alive()
{
	ping $1
	if [ $? -eq 1 ]; then
		return 1
	fi

	# Check rsh client
	error=$(rsh -n $1 "hostname > /dev/null 2>&1; echo \$?")
	if [ $error != 0 ]; then
		return 1
	fi

	return 0
}

#
# Function ce_disk_space
#
# This function checks whether the system
# have enough free disk space to run this case.
#

function ce_disk_space
{

	DF=/usr/sbin/df
        print "checkenv: ce_disk_space($*)"
        errmsg="usage: ce_disk_space <dir> <space_limit> [host]"
	[ $# -lt 2 -o $# -gt 3 ]&& abort $errmsg

        req_label="disk space"
        req_value="$1 $2 $3"

        if [ $OPERATION == "dump" ]; then
                ce_disk_space_doc
                return $PASS
        fi

	errmsg="The $1 on host $3 should greater than $2"
        result=FAIL
        if [ $OPERATION == "verify" ]; then

		if [ -z "$3" ]; then
			space_available=$($DF -b $1 | \
			    grep -v Filesystem | awk '{print $2}')
                	(( $space_available > $2 )) &&
			errmsg="" && result=PASS
	
		else
			#
			# Check the host availability
			#
			check_host_alive $3
			if [ $? -ne 0 ]; then
				echo "Ping or rsh/rexec $1 FAILED!"
				exit 1
			fi
			space_available=$(rsh -n $3 $DF -b $1 | \
			    grep -v Filesystem | awk '{print $2}')
                	(( $space_available > $2 )) &&
			errmsg="" && result=PASS
		fi
        fi

        print_line $TASK "$req_label" "$req_value" "$result" "$errmsg"
        eval return \$$result
}


function ce_disk_space_doc
{
        cat >&1 << EOF

Check ce_disk_space $(TASK)
=================================
Description:
        check  whether the system have enough free disk space to run this case
Arguments:
        #1 - the path name where the datafile is located
        #2 - the free space limit needed by this data file of this test case
	#3 - the host need to be checked, optional for local host

Requirement label (for this check):
        $req_label
Requirement value (for this check):
        $req_value
EOF
}
