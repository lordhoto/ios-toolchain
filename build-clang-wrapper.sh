#!/bin/bash
#
# Copyright (c) 2016 Johannes Schickel <lordhoto@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# NLS nuisances.
LC_ALL=C
export LC_ALL
LANGUAGE=C
export LANGUAGE

function verbose_cmd {
    echo "$@"
    eval "$@"
}

if [ -z "$IOS_TOOLCHAIN_BASE" ]; then
	echo "ERROR: \$IOS_TOOLCHAIN_BASE needs to be set to the path where clang should be installed."
	exit 1
fi
IOS_TOOLCHAIN_BASE=`realpath $IOS_TOOLCHAIN_BASE`

if [ -u "$TARGET" ]; then
	echo "ERROR: $TARGET needs to be set to the target triple."
	exit 1
fi
TARGET_BIN_DIR="$IOS_TOOLCHAIN_BASE/$TARGET/bin"

if [ -z "$IOS_SDK" ]; then
	echo "ERROR: \$IOS_SDK needs to be set to the directory containing the iOS SDK."
	exit 1
fi
IOS_SDK=`realpath $IOS_SDK`
IOS_SDK_VERSION=$(echo `basename "$IOS_SDK"` | grep -P -o '[0-9]+.[0-9]+')
if [ -z "$IOS_SDK_VERSION" ]; then
	echo "ERROR: Could not determine SDK version. It needs to be present in the SDK's directory name."
	exit 1
fi

if [ -z "$IOS_MIN_VER" ]; then
	IOS_MIN_VER=$IOS_SDK_VERSION
fi

# Determine compiler base names based on the version the user requests.
if [ -z "$CLANG_VERSION" ]; then
	CLANG_CC=clang
	CLANG_CXX=clang++
else
	CLANG_CC=clang-$CLANG_VERSION
	CLANG_CXX=clang++-$CLANG_VERSION
fi

# Look up ld linker version.
LINKER_VERSION=$("$IOS_TOOLCHAIN_BASE/$TARGET/bin/$TARGET-ld" -v 2>&1 | head -1)
if [ -z "$LINKER_VERSION" ]; then
	echo "ERROR: Could not determine ld version."
	exit 1
fi

if [ -z "$CXX" ]; then
	CXX=g++
fi

echo "Building clang-wrapper for target $TARGET with ld $LINKER_VERSION, SDK version $IOS_SDK_VERSION and target version $IOS_MIN_VER..."

WRAPPER_BIN="\"$TARGET_BIN_DIR/clang-wrapper\""
verbose_cmd $CXX -std="c++98" -O2 -Wall -pedantic src/clang-wrapper/clang-wrapper.cpp \
	-DLINKER_VERSION="\\\"$LINKER_VERSION\\\"" \
	-DIOS_SDK_DEFAULT="\\\"$IOS_SDK\\\"" \
	-DIOS_MIN_VER_DEFAULT="\\\"$IOS_MIN_VER\\\"" \
	-o "$WRAPPER_BIN"

# Create symlinks
CC_LINK="$TARGET_BIN_DIR/$TARGET-$CLANG_CC"
rm -f "$CC_LINK"
verbose_cmd ln -sr "\"$WRAPPER_BIN\"" "\"$CC_LINK\""

CXX_LINK="$TARGET_BIN_DIR/$TARGET-$CLANG_CXX"
rm -f "$CXX_LINK"
verbose_cmd ln -sr "\"$WRAPPER_BIN\"" "\"$CXX_LINK\""
