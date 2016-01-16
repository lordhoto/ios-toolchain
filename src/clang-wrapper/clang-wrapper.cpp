/* Copyright (c) 2016 Johannes Schickel <lordhoto@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// This utility is based on iphonesdk-utils 2.0 by 
// cjacker <cjacker@gmail.com> and yetist <yetist@gmail.com>
// It also takes inspirations from Thomas Poechtrager's wrapper utility

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <stdio.h>
#include <libgen.h>
#include <unistd.h>

#ifdef __APPLE__
	#define LIBRARY_PATH "DYLD_LIBRARY_PATH"
#else
	#define LIBRARY_PATH "LD_LIBRARY_PATH"
#endif

#ifdef TARGET_MACOS_X
	#define SDK_ENV "MACOSX_SDK"
	#define DEPLOYMENT_TARGET "MACOSX_DEPLOYMENT_TARGET"
	#define MIN_OS_VER_PARAM "-mmacosx-version-min"
#else
	#define SDK_ENV "IOS_SDK"
	#define DEPLOYMENT_TARGET "IPHONEOS_DEPLOYMENT_TARGET"
	#define MIN_OS_VER_PARAM "-miphoneos-version-min"
#endif

extern char **environ;

const char *getFilename(const char *path);
void splitCompilerName(const char *filename, std::string *target, std::string *compilerCommand);
std::string getBaseDir(const std::string &command);
std::string getBaseName(const char *pathName);
const char *getenvd(const char *env, const char *defaultValue);
bool hasPrefix(const char *str, const char *prefix);

int main(int argc, char *argv[]) {
	const char *filename = getFilename(argv[0]);

	std::string target, compilerCommand;
	splitCompilerName(filename, &target, &compilerCommand);

	std::string compilerBaseDir = getBaseDir(compilerCommand);
	if (compilerBaseDir.size() && compilerBaseDir[compilerBaseDir.size() - 1] != '/') {
		compilerBaseDir += '/';
	}
	compilerCommand = compilerBaseDir + "bin/" + compilerCommand;

	// Determine SDK and deployment settings.
	const char *sdkPath   = getenvd(SDK_ENV, SDK_DEFAULT);
	const char *osMinVer = getenvd(DEPLOYMENT_TARGET, MIN_VER_DEFAULT);
	unsetenv(DEPLOYMENT_TARGET);

	std::string osMinVerParam = MIN_OS_VER_PARAM "=";
	osMinVerParam += osMinVer;

	const char *arch;
#ifdef TARGET_MACOS_X
	// Set default archtitecture based on triple's architecture
	const char *dash = strchr(filename, '-');
	if (!dash) {
		abort();
	}
	arch = strdup(std::string(filename, (dash - filename)).c_str());
#else
	// Set default archtitecture based on minimum iOS version.
	int major = -1, minor = -1;
	if (sscanf(osMinVer, "%d.%d", &major, &minor) != 2) {
		abort();
	}

	// armv6 devices only support up to iOS 4.2.1. If we deploy for such an
	// old version, we default to that architecture.
	if (major <= 4 && minor <= 2) {
		arch = "armv6";
	} else {
		arch = "armv7";
	}

	// Make sure all program binaries created are automatically signed.
	std::string codesign = target + "-codesign_allocate";
	setenv("CODESIGN_ALLOCATE", codesign.c_str(), 1);
	setenv("IOS_FAKE_CODE_SIGN", "1", 1);
#endif

	// Setup environment for proper execution.
	std::string newLdLibraryPath = compilerBaseDir;
	newLdLibraryPath += "lib";

	char *ldLibraryPath = getenv(LIBRARY_PATH);
	if (ldLibraryPath && *ldLibraryPath) {
		newLdLibraryPath += ':';
		newLdLibraryPath += ldLibraryPath;
	}
	setenv(LIBRARY_PATH, newLdLibraryPath.c_str(), 1);

	// Setup command line arguments for compiler.
	char **params = (char **)malloc(sizeof(char *) * (argc + 9));

	bool hasArch = false;
	bool hasOSVersionMin = false;
	for (int i = 1; i < argc; ++i) {
		if (hasPrefix(argv[i], "-arch")) {
			hasArch = true;
			break;
		} else if (hasPrefix(argv[i], MIN_OS_VER_PARAM)) {
			hasOSVersionMin = true;
			break;
		}
	}

	int param = 0;
#define ADD_PARAM(x) params[param++] = strdup((x))
	ADD_PARAM(compilerCommand.c_str());
	ADD_PARAM("-target");
	ADD_PARAM(target.c_str());

	if (!hasArch) {
		ADD_PARAM("-arch");
		ADD_PARAM(arch);
	}

	ADD_PARAM("-isysroot");
	ADD_PARAM(sdkPath);

	if (!hasOSVersionMin) {
		ADD_PARAM(osMinVerParam.c_str());
	}

	ADD_PARAM("-mlinker-version=" LINKER_VERSION);
#undef ADD_PARAM

	for (int i = 1; i < argc; ++i) {
		params[param++] = argv[i];
	}

	params[param] = 0;

	execvp(compilerCommand.c_str(), params);

	abort();
}

const char *getFilename(const char *path) {
	const char *filename = strrchr(path, '/');
	if (filename) {
		return filename + 1;
	} else {
		return path;
	}
}

void splitCompilerName(const char *filename, std::string *target, std::string *compilerCommand) {
	const char *command = strrchr(filename, '-');
	if (!command) {
		abort();
	}

	*compilerCommand = std::string(command + 1);
	*target          = std::string(filename, (command - filename));
}

std::string getBaseDir(const std::string &command) {
	char *begin = getenv("PATH");
	if (!begin) {
		abort();
	}
	char *end;

	char path[PATH_MAX + 1];
	path[PATH_MAX] = 0;

	do {
		end = begin;
		while (*end && *end != ':')
			++end;

		std::string commandPath(begin, (end - begin));
		commandPath += '/';
		commandPath += command;

		if (realpath(commandPath.c_str(), path)) {
			char *bin = dirname(path);
			strncpy(path, bin, PATH_MAX);
			return dirname(path);
		}
	} while ((begin = end + 1), *end);

	abort();
}

std::string getBaseName(const char *pathName) {
	char path[PATH_MAX + 1];
	path[PATH_MAX] = 0;

	if (!realpath(pathName, path)) {
		abort();
	}

	return basename(path);
}

const char *getenvd(const char *env, const char *defaultValue) {
	char *value = getenv(env);
	if (value) {
		return value;
	} else {
		return defaultValue;
	}
}

bool hasPrefix(const char *str, const char *prefix) {
	size_t prefixLen = strlen(prefix);
	return (strncmp(str, prefix, prefixLen) == 0);
}
