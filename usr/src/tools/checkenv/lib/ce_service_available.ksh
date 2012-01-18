#
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
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
	error=`rsh -n $1 "hostname > /dev/null 2>&1; echo \$?"`
	if [ $error != 0 ]; then
		return 1
	fi

	return 0
}

#
# Function ce_service_available
#
# This function checks if the given service available on given host
#

function ce_service_available
{
        print "checkenv: ce_service_available($*)"

        errmsg="usage: ce_service_available <smf service name> [hostname]"
        [ $# -lt 1 -o $# -gt 2 ] && abort $errmsg

        req_label="service available"
        req_value=$1

        if [ $OPERATION == "dump" ]; then
                ce_service_available_doc
                return $PASS
        fi

	errmsg=""
        result=PASS
        if [ $OPERATION == "verify" ]; then
	
		if [ -z "$2" ]; then
			STATUS=`svcs -a | grep $1 | \
			    awk '{print $1}'`
			if [ $STATUS != "online" ]; then
	        		[ $? -ne 0 ] && result=FAIL &&
				errmsg="The $1 is not online on localhost"
			fi
		else
			#
			# Check the host availability
			#
			check_host_alive $2
			if [ $? -ne 0 ]; then
				echo "Ping or rsh/rexec $2 FAILED!"
				exit 1
			fi

			STATUS=`rsh -n $2 svcs -a | \
			    grep $1 | \
			    awk '{print $1}'`

			if [ $STATUS != "online" ]; then
	        		[ $? -ne 0 ] && result=FAIL &&
				errmsg="The $1 is not online on host $2"
			fi
		fi
        fi

        print_line $TASK "$req_label" "$req_value" "$result" "$errmsg"
        eval return \$$result

}

function ce_service_available_doc
{
        cat >&1 << EOF

Check ce_service_available $(TASK)
=================================
Description:
        check whether the given service available on given host
Arguments:
        #1 - the smf service name
        #2 - the name of the host, optional for local host
Requirement label (for this check):
        $req_label
Requirement value (for this check):
        $req_value
EOF
}
