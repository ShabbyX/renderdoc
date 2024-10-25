#!/bin/sh

CLANG_MAJOR=15
CLANG_MINOR=0

CLANG_FORMAT_VERSION=$CLANG_MAJOR.$CLANG_MINOR

# Locate the clang-format executable. We try:
#   - the existing value of $CLANG_FORMAT
#   - the first command line argument to the script
#   - in order:
#      clang-format-Maj.Min
#      clang-format-Maj
#      clang-format

# define a function to check the current $CLANG_FORMAT
valid_clang_format() {
	if which "$CLANG_FORMAT" > /dev/null 2>&1; then
		if "$CLANG_FORMAT" --version | grep -q $CLANG_FORMAT_VERSION; then
			echo "Located $CLANG_FORMAT";
			return 0;
		fi
	fi

	return 1;
}

if ! valid_clang_format; then
	# if not valid yet, first try the command line parameter
	CLANG_FORMAT="$1"
fi;

if ! valid_clang_format; then
	# Next try the full version
	CLANG_FORMAT=clang-format-$CLANG_MAJOR.$CLANG_MINOR
fi;

if ! valid_clang_format; then
	# Then -maj just in case
	CLANG_FORMAT=clang-format-$CLANG_MAJOR
fi;

if ! valid_clang_format; then
	# Then finally with no version suffix
	CLANG_FORMAT=clang-format
fi;

# Check if we have a valid $CLANG_FORMAT
if ! valid_clang_format; then
	SCRIPTDIR=$(dirname $(readlink -f $0));
	# If we didn't find one, fall back to repo-included binary. Check it can run
	if "${SCRIPTDIR}"/clangformat/clang-format-15.0.exe --version 2>&1 | grep -q 15.0.7;
	then
		CLANG_FORMAT="${SCRIPTDIR}"/clangformat/clang-format-15.0.exe
	elif "${SCRIPTDIR}"/clangformat/clang-format-15.0 --version 2>&1 | grep -q 15.0.7;
	then
		CLANG_FORMAT="${SCRIPTDIR}"/clangformat/clang-format-15.0
	fi
fi

if ! valid_clang_format; then
	echo "Couldn't find correct clang-format version, was looking for $CLANG_FORMAT_VERSION"
	echo "Renderdoc requires a very specific clang-format version to ensure there isn't any"
	echo "variance between versions that can happen. You can install it as"
	echo "'clang-format-$CLANG_FORMAT_VERSION' so that it doesn't interfere with any other"
	echo "versions you might have installed, and this script will find it there"
	echo "The repository includes a windows and linux x64 binary version, but it failed to run."
	exit 1;
fi;

# Search through the code that should be formatted, exclude any non-renderdoc code.
find qrenderdoc/ renderdoc/ renderdoccmd/ renderdocshim/ util/test/demos/ -name "3rdparty" -prune -o -name "official" -prune -o -print | grep -E ".*\.(h|c|cpp|m|mm|inl|geom|frag|vert|comp|hlsl)$" | grep -E -v "resource.h$" | awk '{printf("%s%c",$0,0)}' | xargs -P 8 -0 -n1 "$CLANG_FORMAT" -i -style=file
