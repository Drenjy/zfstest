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
# ident	"@(#)stf_create_Makefile.config.ksh	1.7	08/11/21 SMI"
#

#
# Description:
#	Locate or generate a Makefile.config for inclusion by
#	Makefile.master.  The file Makefile.config.template
#	provides the raw input used to generate Makefile.config.
#	Every line is eval'd and printed into Makefile.config.
#
#	This file contains the definition for the configlookup 
#	function described in Makefile.config.template.
#

#
# Turn on debugging if necessary.
#
typeset xo=0
typeset me=$(basename $(whence ${0}));
if [[ ${__DEBUG} == *:${me}:* ]]; then
	[[ -o xtrace ]]  && typeset xo=1
	set -o xtrace
fi

typeset amname="STF_MACH_MODEL"
typeset mmname="STF_MEMORY_MODEL"
typeset fomname="STF_FILE_OFFSET_MODEL"
typeset mode=""

typeset usage="

 $me <target directory> <master config directory> <list of override directories>

 Description:
	Locate and/or construct Makefile.config.

 Parameters:
	<pa>	Input - required
		Class of processor architecture. Presently only SPARC and i386
		are spported (as returned by \`uname -p\`)

	<mm>	Input - required
		Memory address model. Presently the following keywords are
		supported: LP64, ILP32

	<fom>	Input - required
		File offset model. Presently the following keywords are
		supported: F32, F64

	<WS_ROOT>	Input - optional
		Workspace root.  The path to the current workspace if
		appropriate. If WS_ROOT exists in the envrironment, then
		this parameter may be omitted. Since binary execution of STC
		test suites does not require a workspace, this parameter may
		be null.

 Return value:
	Path to Makefile.config

"
#
# Collect my parameters.
#

if (( ${#} < 3 )); then
  print "\n**** Error: Missing parameters"
  print
  print "${0} ${@}"
  print
  print "${usage}"
  return 1

fi >&2

typeset targetdir=${1}
typeset modelist=${2}
typeset configinputs=${3}


#
# Compute the location of Makefile.master using the path to this script.
#
typeset -x myloc=$(dirname $(whence ${0}))

#
# configlookup
#
# Descripion:
#	A general purpose lookup routine that presumes defaults based on the
#	parameters passed to the main.
#
function configlookup {

  #
  # Turn on debugging if necessary.
  #
  typeset xo=0
  typeset vo=0
  if [[ ${__DEBUG} == *:${me}:* ]]; then
	  [[ -o xtrace ]]  && typeset xo=1
	  set -o xtrace
  fi

  case ${1} in
    [bB][iI][nN][aA][rR][yY])	# Lookup binary location.

      ${myloc}/stf_configlookupbinary \
       BinaryLocation \
       ${mode} \
       ${configinputs}

      break
      ;;

    [tT][oO][oO][lL])		# Lookup tool path.

      eval typeset PATH=$(${myloc}/stf_configlookuptool \
       BuildTools \
       ${mode} \
       ${2} \
       PATH \
       ${configinputs})

      eval typeset ALIAS=$(${myloc}/stf_configlookuptool \
       BuildTools \
       ${mode} \
       ${2} \
       ALIAS \
       ${configinputs})

      whence ${ALIAS}
      break
      ;;

    [fF][lL][aA][gG][sS])	# Lookup tool flags.

      ${myloc}/stf_configlookuptool \
       BuildTools \
       ${mode} \
       ${2} \
       FLAGS \
       ${configinputs} \

      break
      ;;

    *)
      print "**** Error: Unrecognized keyword ${1}." >&2
      return 1
      ;;

  esac

  #
  # Turn off any debugging turned on specifically for this script.
  #
  (( xo == 0 )) && set +o xtrace
}

#
# Figure out where the binary tree should be for these parameters and see if a 
# config file has already been created.
#
 
[[ ! -d $targetdir ]] && /usr/bin/mkdir -p $targetdir

for mode in $modelist ; do

	if [[ $mode = "none" ]] ; then
		target=$targetdir/Makefile.config;
	else
            	target=$targetdir/Makefile.config.$mode;
	fi

	rebuild=false
	if [[ -f $target ]] ; then

		for file in $configinputs ; do
	
			[[ $target -ot $file ]] && rebuild=true
		done

		[[ $target -ot ${myloc}/Makfile.config.template ]] &&
		    rebuild=true
	else
		rebuild=true
	fi

	[[ $rebuild = "false" ]] && continue

	#
	# Okay, so no file exists there. Lets make one...
	#
	
	typeset idline="
	#
	# Warning!
	#
	# Programmatically generated files. Do not modify.
	#
	
	#
	# Model specifications.
	#
	Mode=${mode}
	#
	
	"
	print "${idline}" > ${target}
	
	#
	# Process every line of the template file.
	#
	while read aline; do
	  if [[ ! ${aline} = \#* ]] ; then
	  	eval aline=\"${aline}\"
	  fi
	  print "${aline}" >> ${target}
	
	done < ${myloc}/Makefile.config.template
	
done

# Turn off any debugging turned on specifically for this script.
#

(( xo == 0 )) && set +o xtrace

#
# Return the name of the config file.
#
print ${targetdir}/Makefile.config
return 0
