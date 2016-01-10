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

BUILD_DIR=build/

if [ -z "$PARALLELISM" ]; then
	PARALLELISM=2
fi

if [ -z "$PACKAGE" ]; then
	echo "ERROR: \$PACKAGE not set."
	exit 1
fi
if [ -z "$PACKAGE_FILE" ]; then
	echo "ERROR: \$PACKAGE_FILE not set."
	exit 1
fi

if [ -z "$IOS_TOOLCHAIN_BASE" ]; then
	echo "ERROR: \$IOS_TOOLCHAIN_BASE needs to be set to toolchain's base directory."
	exit 1
fi
IOS_TOOLCHAIN_BASE=`realpath $IOS_TOOLCHAIN_BASE`

if [ -z "$TARGET" ]; then
	echo "ERROR: $TARGET needs to be set to the target triple."
	exit 1
fi
TARGET_BASE="$IOS_TOOLCHAIN_BASE/$TARGET"

export PATH="$IOS_TOOLCHAIN_BASE/bin:$TARGET_BASE/bin:$TARGET_BASE/usr/bin:$PATH"

mkdir -p "$BUILD_DIR"
pushd "$BUILD_DIR" &>/dev/null

echo "Preparing sources for $PACKAGE..."

case "$PACKAGE_FILE" in
	*.tar.*)
		tar xf "$PACKAGE_FILE"
		;;
	*)
		echo "ERROR: Unsupported package type."
		exit 1
		;;
esac

echo "Building $PACKAGE for $TARGET..."

pushd "$PACKAGE" &>/dev/null
verbose_cmd make CC="\"$TARGET-clang\"" AR="\"$TARGET-ar\"" RANLIB="\"$TARGET-ranlib\"" -j$PARALLELISM libbz2.a "&>build.log" || exit 1
mkdir -p "$TARGET_BASE/usr/lib/"
verbose_cmd cp libbz2.a "$TARGET_BASE/usr/lib/" || exit 1
mkdir -p "$TARGET_BASE/usr/include/"
verbose_cmd cp bzlib.h "$TARGET_BASE/usr/include/" || exit 1
popd &>/dev/null

popd &>/dev/null

echo "Successfully built libbz2."
chmod -R u+w "$BUILD_DIR"
rm -r "$BUILD_DIR"
