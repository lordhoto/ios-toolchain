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

VERSION=0.29
TARGETS="arm-apple-darwin9 arm-apple-darwin11 ppc-apple-darwin8"

SOURCE_DIR=`pwd`
BUILD_DIR=build/
if [ -z "PARALLELISM" ]; then
	PARALLELISM=2
fi

if [ -z "$IOS_TOOLCHAIN_BASE" ]; then
	echo "ERROR: \$IOS_TOOLCHAIN_BASE needs to be set to the path where pkg-config should be installed."
	exit 1
fi
IOS_TOOLCHAIN_BASE=`realpath "$IOS_TOOLCHAIN_BASE"`

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Downloading pkg-config $VERSION sources..."

wget -c -nv --show-progress --progress=bar:force http://pkgconfig.freedesktop.org/releases/pkg-config-$VERSION.tar.gz || exit 1

echo "Preparing soucres..."

tar xf pkg-config-$VERSION.tar.gz || exit 1

cd "pkg-config-$VERSION"

for i in $TARGETS; do
	echo "Building pkg-config for $i..."
	"./configure" --prefix="$IOS_TOOLCHAIN_BASE/$i/usr" --disable-host-tool &>build.log || exit 1
	make -j$PARALLELISM &>build.log || exit 1
	make install &>build.log || exit 1
	rm -f "$IOS_TOOLCHAIN_BASE/$i/usr/bin/$i-pkg-config"
	ln -sr "$IOS_TOOLCHAIN_BASE/$i/usr/bin/pkg-config" "$IOS_TOOLCHAIN_BASE/$i/usr/bin/$i-pkg-config"
	make distclean &>build.log || exit 1
done

echo "Removing build directory..."

cd "$SOURCE_DIR"

rm -r "$BUILD_DIR"
