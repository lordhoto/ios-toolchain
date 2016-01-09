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

LLVM_VERSION=3.7.1

SOURCE_DIR=`pwd`
BUILD_DIR=build/
if [ -z "PARALLELISM" ]; then
	PARALLELISM=2
fi

LLVM_PACKAGES="llvm cfe compiler-rt"

if [ -z "$IOS_TOOLCHAIN_BASE" ]; then
	echo "ERROR: \$IOS_TOOLCHAIN_BASE needs to be set to the path where clang should be installed."
	exit 1
fi
IOS_TOOLCHAIN_BASE=`realpath $IOS_TOOLCHAIN_BASE`

if [ -z "$NATIVE_ARCH" ]; then
	# TODO: Pick native archtiecture in an automated fashion.
	NATIVE_ARCH=X86
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Downloading llvm+clang $LLVM_VERSION sources..."

for i in $LLVM_PACKAGES; do
	URL="http://llvm.org/releases/$LLVM_VERSION/$i-$LLVM_VERSION.src.tar.xz"
	wget -c -nv --show-progress --progress=bar:force $URL || exit 1
done

echo "Preparing soucres..."

for i in $LLVM_PACKAGES; do
	rm -rf $i-$LLVM_VERSION.src
	xz -dc $i-$LLVM_VERSION.src.tar.xz | tar xf - || exit 1
done

mv cfe-$LLVM_VERSION.src llvm-$LLVM_VERSION.src/tools/clang
mv compiler-rt-$LLVM_VERSION.src llvm-$LLVM_VERSION.src/projects/compiler-rt

cd llvm-$LLVM_VERSION.src
for i in `ls "$SOURCE_DIR/patches/clang/"`; do
	patch -p1 < "$SOURCE_DIR/patches/clang/$i" || exit 1
done
cd ..

echo "Building clang..."

mkdir -p clang-build
cd clang-build
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$IOS_TOOLCHAIN_BASE" \
      -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="$NATIVE_ARCH;ARM" \
      ../llvm-$LLVM_VERSION.src || exit 1
make -j$PARALLELISM || exit 1
make install || exit 1
cd ..

cd "$SOURCE_DIR"

echo "Removing build directory..."

rm -r "$BUILD_DIR"
