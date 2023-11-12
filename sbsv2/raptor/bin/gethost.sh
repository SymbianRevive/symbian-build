#!/bin/bash


# Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
# Determine hosttype
#
#

# Print out a list of host information in order of significance.
# for use within Makefiles and other scripts.
# The idea is that it should be possible to use it for simple decisions
# e.g. windows/linux and more complex ones e.g. i386/x86_64

getopts de  OPT

if [[ "${OSTYPE}" =~ "linux" ]]; then
	ARCH=$(uname -m)
	LIBC=$(LANG=C /lib/libc.so.6 |sed -rn 's/^GNU C Library .* version ([0-9]+)\.([0-9]+).*/libc\1_\2/p')
        HOSTPLATFORM="linux ${ARCH} ${LIBC}"

	HOSTPLATFORM_DIR="linux-${ARCH}"
elif [[ "$OS" == "Windows_NT" ]]; then
	HOSTPLATFORM="win 32"
	HOSTPLATFORM_DIR="win32"
else
	HOSTPLATFORM=unknown
	HOSTPLATFORM_DIR=unknown
fi

if [ "$OPT" == "e" ]; then 
	echo "export HOSTPLATFORM_DIR=$HOSTPLATFORM_DIR"
	echo "export HOSTPLATFORM='$HOSTPLATFORM'"
elif [ "$OPT" == "d" ]; then 
	echo "$HOSTPLATFORM_DIR"
else
	echo "$HOSTPLATFORM"
fi
