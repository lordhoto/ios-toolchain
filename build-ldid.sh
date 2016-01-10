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

SOURCE_DIR=`pwd`
BUILD_DIR=build/
if [ -z "PARALLELISM" ]; then
	PARALLELISM=2
fi

if [ -z "$IOS_TOOLCHAIN_BASE" ]; then
	echo "ERROR: \$IOS_TOOLCHAIN_BASE needs to be set to the path where ldid should be installed."
	exit 1
fi
IOS_TOOLCHAIN_BASE=`realpath $IOS_TOOLCHAIN_BASE`

REVISION="3064ed628108da4b9a52cfbe5d4c1a5817811400"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Downloading ldid $REVISION sources..."

wget -c -nv --show-progress --progress=bar:force https://github.com/tpoechtrager/ldid/archive/$REVISION.zip || exit 1

echo "Preparing soucres..."

unzip -o $REVISION.zip || exit 1

echo "Building ldid..."

cd "ldid-$REVISION"
make INSTALLPREFIX=$IOS_TOOLCHAIN_BASE -j$PARALLELISM install

echo "Removing build directory..."

cd "$SOURCE_DIR"

rm -r "$BUILD_DIR"
