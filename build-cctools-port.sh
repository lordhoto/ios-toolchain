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

REVISION="4f8ad519f7fa49e3c6374263c9bc223690b09fc1"
TARGETS="arm-apple-darwin9 arm-apple-darwin11"

SOURCE_DIR=`pwd`
BUILD_DIR=build/
if [ -z "PARALLELISM" ]; then
	PARALLELISM=2
fi

if [ -z "$IOS_TOOLCHAIN_BASE" ]; then
	echo "ERROR: \$IOS_TOOLCHAIN_BASE needs to be set to the path where cctools-port should be installed."
	exit 1
fi
IOS_TOOLCHAIN_BASE=`realpath "$IOS_TOOLCHAIN_BASE"`

if [ -z "$LLVM_CONFIG" ]; then
	LLVM_CONFIG=`which llvm-config 2>/dev/null || echo ""`
	if [ -z "$LLVM_CONFIG" ]; then
		echo "ERROR: No llvm-config found. Please update your \$PATH or set \$LLVM_CONFIG."
		exit 1
	fi
fi
LLVM_CONFIG=`realpath "$LLVM_CONFIG"`
CLANG_BASE=`dirname "$LLVM_CONFIG"`
CLANG_BASE=`dirname "$CLANG_BASE"`

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Downloading cctools-port $REVISION sources..."

wget -c -nv --show-progress --progress=bar:force https://github.com/tpoechtrager/cctools-port/archive/$REVISION.zip || exit 1

echo "Preparing soucres..."

unzip -o $REVISION.zip || exit 1

echo "Building cctools-port..."

PATH_SAVE="$PATH"
LD_LIBRARY_PATH_SAVE="$LD_LIBRARY_PATH"

PATH="$CLANG_BASE/bin:$PATH"
LD_LIBRARY_PATH="$CLANG_BASE/lib:$LD_LIBRARY_PATH"

cd cctools-port-$REVISION/cctools/
# On some 32bit Linux systems PTHREAD_MUTEX_RECURSIVE is not available by
# default. We define _GNU_SOURCE to make it available.
CPPFLAGS="-D_GNU_SOURCE"
for i in $TARGETS; do
	echo "Building target $i..."
	./autogen.sh >/dev/null || exit 1
	./configure --prefix="$IOS_TOOLCHAIN_BASE/$i" --target="$i" --with-llvm-config="$LLVM_CONFIG" --disable-clang-as >/dev/null || exit 1
	make -j$PARALLELISM >/dev/null || exit 1
	make install >/dev/null || exit 1
	make distclean >/dev/null || exit 1
done

PATH=$PATH_SAVE
LD_LIBRARY_PATH="$LD_LIBRARY_PATH_SAVE"

echo "Removing build directory..."

cd "$SOURCE_DIR"

rm -r "$BUILD_DIR"
