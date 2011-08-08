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
# Copyright 2007 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# ident	"@(#)ce_nfs_server.ksh	1.3	07/01/04 SMI"
#

#
# Function ce_nfs_server
#
# This function checks that the NFS server is configured and is sharing
# the NFS path.
#
function ce_nfs_server
{
	nfs_server=$1
	nfs_path=$2
	nfs_mode=$3

	result=PASS	
	resultmsg=

	errmsg="ce_nfs_server expects 3 arguments (NFS_SERVER NFS_PATH mode)"

        # Check the argument and make sure it is as expected - abort
	# otherwise.
	#
	[[ $# -ne 3 ]] && abort $errmsg

	[[ $nfs_mode != "ro" && $nfs_mode != "rw" ]] && abort invalid mode $nfs_mode


	# Set requirement label information (field #2 of output)
	req_label="NFS mount required"

	# Set requirement label information (field #3 of output)
	req_value="\$$nfs_server:\$$nfs_path ($nfs_mode)"

	# If operation is to dump info, dump and return
	[[ $OPERATION = "dump" ]] && {
		ce_nfs_server_doc
		return $PASS
	}

	[[ $OPERATION = "verify" ]] && {

		nfs_server_value=$(eval echo \$${nfs_server})
		nfs_path_value=$(eval echo \$${nfs_path})
	
		[[ -z "${nfs_server_value}" ]] && 
			abort "${nfs_server} not set - checkenv aborting"
		[[ -z "${nfs_path_value}" ]] && 
			abort "${nfs_value} not set - checkenv aborting"

		ping ${nfs_server_value} > /dev/null 2>&1
		if [[ $? -ne 0 ]] 
		then
			result=FAIL 
			resultmsg="server ${nfs_server_value} not responding"
		else
			tmpdir=/var/tmp/xyz.$$
			mkdir $tmpdir > /dev/null 2>&1
			[[ $? -ne 0 ]] && abort "Unable to create tmpdir $tmpdir - check aborted"
			mount -o ${nfs_mode} ${nfs_server_value}:${nfs_path_value} $tmpdir > /dev/null 2>&1
			[[ $? -ne 0 ]] && {
				result=FAIL
				resultmsg="${nfs_server_value}:${nfs_path_value} ($nfs_mode) could not be mounted"
			}
			umount $tmpdir > /dev/null 2>&1
			rmdir  $tmpdir > /dev/null 2>&1
		fi
	}

	# print checkenv results
	print_line $TASK "$req_label" "$req_value" "$result" "$resultmsg"

	# return result code
	eval return \$$result
}

function ce_nfs_server_doc
{
	cat >&1 << EOF

Check ce_nfs_server ($TASK)
===============================
Description:
	Test requires NFS server.  The test will need an NFS mount 
	from the server.  
Arguments:
	#1 - Configuration variable name used to designate the 
	     NFS server (e.g. STC_NFS_SERVER_ROSHARE)
	#2 - Configuration variable used to designate the share path 
	     on the NFS server (e.g. STC_NFSPATH_RO)
	#3 - mode (Value should be ro (read-only) or rw (read-write))
Requirement label (for this check):
	$req_label
Requirement value (for this check):
	$req_value
EOF
}
