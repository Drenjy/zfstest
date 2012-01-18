#!/usr/bin/ksh
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
# Function ce_arch_coherence
# This function checks if this test suite can support
# the current architecture of local host and remote host.
# Operation "dump" will display the function of this check.
# If the two sides have different arch, the testsuite
# on server side should have both client and server's
# arch's binaries
#

function ce_arch_coherence
{
        print "checkenv: ce_arch_coherence($*)"

        errmsg="usage: ce_arch_coherence <LOCAL_HST> <RMT_HST>"
        [ $# -ne 2 ] && abort $errmsg

        req_label="arch coherence"
        req_value="$1 $2"

	#
	# operation "dump" will display the function of this check
	#
        if [ $OPERATION == "dump" ]; then
                ce_arch_coherence_doc
                return $PASS
        fi

	#
	# Check the host availability
	#
	check_host_alive $2
	if [ $? -ne 0 ]; then
		echo "Ping or rsh/rexec $2 FAILED!"
		exit 1
	fi

	#
	# If the two sides have different arch, the client side
	# should share his test suite directory to the server.
	#
        errmsg="$1 and $2 are different arch, \
please build test suite as README."

        result=FAIL
        if [ $OPERATION == "verify" ]; then
		local_arch=`uname -p`
		remote_arch=`rsh -n $2 "uname -p"`
		if [  "$local_arch" = "$remote_arch" ]; then
			errmsg=""
			result=PASS
		else	
			#
			# Verify the local binaries support for both sides
			#
			rmt_cnt=`find ${STF_SUITE} -name ${remote_arch}* \
			    | wc -l | awk '{print $1}'`
			local_cnt=`find ${STF_SUITE} -name ${local_arch}* \
			    | wc -l | awk '{print $1}'`

			if [ $rmt_cnt -eq $local_cnt ]; then
				errmsg=""
				result=PASS
			fi

		fi
        fi

        print_line $TASK "$req_label" "$req_value" "$result" "$errmsg"
        eval return \$$result
}

function ce_arch_coherence_doc
{
        cat >&1 << EOF

Check ce_arch_coherence $(TASK)
=================================
Description:
        check if this test suite can support the
	current architecture of local host and remote host.
Arguments:
        #1 - the name or IP of the local host
        #2 - the name or IP of the remote host
Requirement label (for this check):
        $req_label
Requirement value (for this check):
        $req_value
EOF
}

