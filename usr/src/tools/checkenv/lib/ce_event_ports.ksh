#! /usr/bin/ksh  -p
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
# ident	"@(#)ce_event_ports.ksh	1.2	07/01/04 SMI"
#

# 
# Function ce_event_ports
#
# Check if ports are supported on the system
#
function ce_event_ports
{
	typeset -l supported_unsupported=${1}

	result=PASS
	ports=

	# Check the argument and make sure it is as expected - abort
	# otherwise.
	#
	errmsg="ce_event_ports expects argument of supported or unsupported "
	[[ $# -ne 1 ]] && abort $errmsg
	[[ $1 != "supported" && $1 != "unsupported" ]] &&  abort $errmsg

	req_label="event_ports"
	req_value="$supported_unsupported"

        # If operation is to dump info, dump and return
	[[ $OPERATION = "dump" ]] && {
		ce_event_ports_doc
		return $PASS
	}

	#
	# Verify that the system meets requirements - set result=[PASS|FAIL]
	#
	[[ $OPERATION = "verify" ]] && {
		result=PASS
		[[ `/usr/xpg4/bin/awk '/^portfs\t/ {print $1}' \
			/etc/name_to_sysnum` = "portfs" ]] && \
			event_ports=TRUE
		[[ "$supported_unsupported" = "supported" ]]  && 
			[[ -z "$event_ports" ]] && result=FAIL
		
		[[ "$supported_unsupported" = "unsupported" ]]  && 
			[[ -n "$event_ports" ]] && result=FAIL
	}

        print_line $TASK "$req_label" "$req_value" "$result"
	eval return \$$result
}

function ce_event_ports_doc
{
	cat >&1 << EOF

Check ce_event_ports ($TASK)
=========================
Description:
	Checks if the system supports ports
Arguments:
	#1 - supported or unsupported (ports are supported or unsupported)
Requirement label (for this check):
	$req_label
Requirement value (for this check):
	$req_value
EOF
}
