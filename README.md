#iOS toolchain#

- Current llvm+clang version: 3.7.1
- Current [cctools-port](https://github.com/tpoechtrager/cctools-port) version: 4f8ad519f7fa49e3c6374263c9bc223690b09fc1
- Current [ldid](https://github.com/tpoechtrager/ldid) version: 3064ed628108da4b9a52cfbe5d4c1a5817811400

Based on work by [cjacker and yetist](https://code.google.com/p/ios-toolchain-based-on-clang-for-linux/) and work by [tpoechtrager](https://github.com/tpoechtrager).

## How to build the toolchain ##

The toolchain can be built using the build scripts found in the root of this
repository. They each require different environment variables to be set. The
most important variable is `IOS_TOOLCHAIN_BASE`. This variable specifies the
base directory where the toolchain shall be installed. It is required for all
build scripts.

### 1. Step: Build clang ###

Building clang is done by executing the `build-clang.sh` script. This script
allows the following configuration variables:

* `PARALLELISM`: Allows to specify the number of jobs `make` shall run
                 simultaneously. This is directly passed to `make` via the
                 `-j` parameter.
                 *Default:* 2.
* `NATIVE_ARCH`: If you are not on x86/amd64, you will need to specify the
                 host type you are running with this variable. It takes
                 llvm's target options. 
                 *Default:* X86.

*Example:*
```
export IOS_TOOLCHAIN_BASE=~/toolchains/ios
export PARALLELISM=9
./build-clang.sh
```

### 2. Step: Build cctools-port ###

Building Apple's cctools is done by executing `build-cctools-port.sh`. This
builds a custom cctools version modified to work on non Darwin systems. The
build can be configured with the following variables:

* `PARALLELISM`: Allows to specify the number of jobs `make` shall run
                 simultaneously. This is directly passed to `make` via the
                 `-j` parameter.
                 *Default:* 2.
* `LLVM_CONFIG`: The llvm-config executable to be used to setup the build.
                 *Default:* The executable found by `which llvm-config`.

*Example:*
```
export IOS_TOOLCHAIN_BASE=~/toolchains/ios
export LLVM_CONFIG="$IOS_TOOLCHAIN_BASE/bin/llvm-config"
export PARALLELISM=9
./build-cctools-port.sh
```

### 3. Step: Build ldid ###

To build the `ldid` tool, which is used to fake sign executables, the
`build-ldid.sh` script is used. Configuration can be done with the following
variables:

* `PARALLELISM`: Allows to specify the number of jobs `make` shall run
                 simultaneously. This is directly passed to `make` via the
                 `-j` parameter.
                 *Default:* 2.

*Example:*
```
export IOS_TOOLCHAIN_BASE=~/toolchains/ios
export PARALLELISM=9
./build-ldid.sh
```

### 4. Step: Build clang-wrapper ###

The `clang-wrapper` tool is a simple wrapper around clang which takes care of
passing the proper flags to clang to build an iOS application. This tool has
support to configure a default iOS target on compilation time, but also allows
to configure the setup on run time. Configuration works by setting the
following variables to appropriate values:

* `TARGET`: The target to configure the wrapper for. `build-cctools-port.sh`
            builds binutils for the following targets:
            - arm-apple-darwin9
            - arm-apple-darwin10
            - arm-apple-darwin11
* `IOS_SDK`: The path to the iOS SDK which will be used by default.
             The SDK's basename needs to include the iOS version the SDK is
             for.
* `PARALLELISM`: Allows to specify the number of jobs `make` shall run
                 simultaneously. This is directly passed to `make` via the
                 `-j` parameter.
                 *Default:* 2.
* `IOS_MIN_VER`: The minimum iOS version the build is targeting.
                 *Default:* Version of the default iOS SDK.
* `CLANG_VERSION`: A version suffix for the clang/clang++ executables wrapped.
                   This allows to use clang executables which are versioned,
                   for example, `clang-3.7`.
                   *Default:* Empty.

*Example:*
```
export IOS_TOOLCHAIN_BASE=~/toolchains/ios
export PARALLELISM=9

TARGET=arm-apple-darwin9 IOS_SDK="$IOS_TOOLCHAIN_BASE/sdks/iPhoneOS4.2.sdk/" IOS_MIN_VER=3.1 ./build-clang-wrapper.sh
TARGET=arm-apple-darwin10 IOS_SDK="IOS_TOOLCHAIN_BASE/sdks/iPhoneOS4.2.sdk/" IOS_MIN_VER=3.1 ./build-clang-wrapper.sh
TARGET=arm-apple-darwin11 IOS_SDK="$IOS_TOOLCHAIN_BASE/sdks/iPhoneOS7.1.sdk/" ./build-clang-wrapper.sh
```

### Famous last words ###

**NOTE**: It may be possible to use an existing llvm/clang build.
However, since llvm/clang 3.7.1 (and possibly other versions) contain a bug
which prevents compiling for ARMv6 targets it is suggested to use the supplied
clang version.

## How to use the toolchain ##

Using the toolchain is really straightforward. The basic steps for compiling a
program targeting iOS are as follows:

* Set up `PATH` to include your clang compiler executable, the cctools
  executables, the `ldid` executable, and the `clang-wrapper` executables.
* Set `CC` and/or `CXX` to the wrapper you want to use for building.

`clang-wrapper` allows you to override the SDK and minimum iOS version
targeted by setting the following environment variables accordingly:

* `IOS_SDK`: Path to the root of the SDK.
* `IPHONEOS_DEPLOYMENT_TARGET`: Minimum iOS version targeted.

*Example:*
```
export IOS_TOOLCHAIN_BASE=~/toolchains/ios
export PATH="$IOS_TOOLCHAIN_BASE/bin:$IOS_TOOLCHAIN_BASE/arm-apple-darwin9/bin:$PATH"
export CXX=arm-apple-darwin9-clang++

$CXX -O3 my-compilation-unit.cpp -o my-ios-binary
```

**NOTE**: Using `-g` to generate debugging information does not work at the
time of writing. This is because it requires Apple's `dsymutil`.

**NOTE**: Using `strip` on iOS executables makes you require to re-sign the
binary. This can be done by running `ldid -S /path/to/binary`.

**NOTE**: Specifying `-miphoneos-version-min=xx.yy` manually on command line
overrides any `clang-wrapper` defaults and the `IPHONEOS_DEPLOYMENT_TARGET`
variable.

## Description of patches ##

* patches/clang/legacy-ios-sdk-support.patch

Allows clang++ to pick up C++ headers for ancient 3.1.3 SDKs.

* patches/clang/macho-armv6k-sub-type.patch

Fixes a bug which causes llvm to generate ARMv7 MachO files when using an
armv6k target.

clang will automatically select an `armv6k` target when building for
`-arch armv6` for iOS. Due to a missing check, llvm will generate armv7 files.
This breaks linking.

## TODO ##

* Integrate `dsymutil` support to allow compilation with debugging information.
* Test toolchain setup on non-Linux/amd64 hosts.
