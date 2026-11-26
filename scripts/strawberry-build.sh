#!/bin/bash
# Builds strawberry.app from a release tarball extracted in <staged-dir>,
# following https://wiki.strawberrymusicplayer.org/wiki/Build_macOS.
# Expects upstream's dependency bundle in /opt/strawberry_macos_arm64_release.
# Leaves only strawberry.app in <staged-dir>.
# Usage: strawberry-build.sh <staged-dir> <version>
set -euo pipefail

staged=$1 version=$2
prefix=/opt/strawberry_macos_arm64_release
src=$staged/strawberry-$version
build=$staged/build

# Build against the dependency bundle only, never against Homebrew libraries.
export PATH=$prefix/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PKG_CONFIG_PATH=$prefix/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$prefix/lib/pkgconfig
export LDFLAGS="-L$prefix/lib -Wl,-rpath,$prefix/lib"
unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH LIBRARY_PATH CMAKE_PREFIX_PATH

# Use the deployment target Qt was built with.
MACOSX_DEPLOYMENT_TARGET=$(otool -l "$prefix/lib/QtCore.framework/QtCore" |
  awk '/LC_BUILD_VERSION/ { b = 1 } !found && b && $1 == "minos" { print $2; found = 1 }')
[[ -n $MACOSX_DEPLOYMENT_TARGET ]]
export MACOSX_DEPLOYMENT_TARGET

# Releases up to 1.2.31 need Boost headers, which the dependency bundle no
# longer ships, and their targets do not add the include directory themselves.
boost_args=()
if grep -q 'find_package(Boost' "$src/CMakeLists.txt"; then
  boost_version=1.92.0
  boost_sha256=5c1d40cb8e19adbf740a4ec2da35b3e58f3f5804b1dce44deb53df72193cbc6c
  boost_dir=boost_${boost_version//./_}
  curl -fsSL --retry 3 -o "$staged/boost.tar.bz2" \
    "https://archives.boost.io/release/$boost_version/source/$boost_dir.tar.bz2"
  echo "$boost_sha256  $staged/boost.tar.bz2" | shasum -a 256 -c
  tar -C "$staged" -xf "$staged/boost.tar.bz2" "$boost_dir/boost"
  boost_args=("-DBoost_INCLUDE_DIR=$staged/$boost_dir")
  export CPLUS_INCLUDE_PATH=$staged/$boost_dir
fi

spotify=OFF
[[ -f $prefix/lib/gstreamer-1.0/libgstspotify.dylib ]] && spotify=ON

cmake -S "$src" -B "$build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$prefix/lib/cmake" \
  -DCMAKE_IGNORE_PREFIX_PATH="/opt/homebrew;/usr/local" \
  -DCMAKE_INSTALL_PREFIX="$staged/install" \
  -DUSE_BUNDLE=ON \
  -DICU_ROOT="$prefix" \
  -DENABLE_SPOTIFY=$spotify \
  -DENABLE_SPARKLE=OFF \
  -DENABLE_QTSPARKLE=OFF \
  ${boost_args[@]+"${boost_args[@]}"}

cmake --build "$build" --parallel "$(sysctl -n hw.ncpu)"
make -C "$build" install
make -C "$build" deploy

# Deploying rewrites the binaries, which invalidates their signatures.
codesign --force --deep --sign - "$build/strawberry.app"
codesign --verify --deep --strict "$build/strawberry.app"

mv "$build/strawberry.app" "$staged/strawberry.app"
find "$staged" -mindepth 1 -maxdepth 1 ! -name strawberry.app -exec rm -rf {} +
