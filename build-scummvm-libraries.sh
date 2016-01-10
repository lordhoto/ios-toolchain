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

SOURCE_DIR=`realpath "${0%/*}"`
export PATCH_DIR="$SOURCE_DIR/patches"
BUILD_DIR=build/
TARGETS="arm-apple-darwin9 arm-apple-darwin11"

if [ -z "$IOS_TOOLCHAIN_BASE" ]; then
	echo "ERROR: \$IOS_TOOLCHAIN_BASE needs to be set to toolchain's base directory."
	exit 1
fi
export IOS_TOOLCHAIN_BASE=`realpath "$IOS_TOOLCHAIN_BASE"`

function setup_library {
	export PACKAGE="$1"
	FILENAME="$1.$2"
	export PACKAGE_FILE="$BUILD_DIR/$FILENAME"
	wget -c -nv --show-progress --progress=bar:force "$3$FILENAME" -O "$PACKAGE_FILE" || exit 1
}

function compile_library {
	for i in $TARGETS; do
		export TARGET="$i"
		"$SOURCE_DIR"/build-library.sh "$@" || exit 1
	done
}

mkdir -p "$BUILD_DIR"
pushd "$BUILD_DIR" &>/dev/null
BUILD_DIR=`pwd`

# FAAD2
setup_library "faad2-2.7" "tar.bz2" "http://sourceforge.net/projects/faac/files/faad2-src/faad2-2.7/"
compile_library

# libogg
setup_library "libogg-1.3.2" "tar.xz" "http://downloads.xiph.org/releases/ogg/"
compile_library

# libvorbis
setup_library "libvorbis-1.3.5" "tar.xz" "http://downloads.xiph.org/releases/vorbis/" 
compile_library

# libtheora
setup_library "libtheora-1.1.1" "tar.bz2" "http://downloads.xiph.org/releases/theora/" 
compile_library --disable-examples

# FLAC
setup_library "flac-1.3.1" "tar.xz" "http://downloads.xiph.org/releases/flac/"
compile_library --disable-xmms-plugin --disable-cpplibs

# FreeType2
setup_library "freetype-2.6.2" "tar.bz2" "http://download.savannah.gnu.org/releases/freetype/"
compile_library

# libjpeg-turbo
setup_library "libjpeg-turbo-1.4.2" "tar.gz" "http://sourceforge.net/projects/libjpeg-turbo/files/1.4.2/"
compile_library

# libpng
setup_library "libpng-1.6.20" "tar.xz" "ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/"
compile_library

# libmad
setup_library "libmad-0.15.1b" "tar.gz" "ftp://ftp.mars.org/pub/mpeg/"
compile_library --enable-fpm=default

# libmpeg2
setup_library "libmpeg2-0.5.1" "tar.gz" "http://libmpeg2.sourceforge.net/files/"
compile_library --disable-sdl

popd &>/dev/null
rm -r "$BUILD_DIR"
