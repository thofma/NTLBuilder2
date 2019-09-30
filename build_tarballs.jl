# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libntl"
version = v"10.5.0"

# Collection of sources required to build libntl
sources = [
    "https://www.shoup.net/ntl/ntl-10.5.0.tar.gz" =>
    "b90b36c9dd8954c9bc54410b1d57c00be956ae1db5a062945822bbd7a86ab4d2",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ntl-10.5.0/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/configure.patch
cd $WORKSPACE/srcdir
CC_OLD=$CC
CC=$CC_FOR_BUILD
CXX_OLD=$CXX
CXX=$CXX_FOR_BUILD
LIBTOOL_OLD=$LIBTOOL
LIBTOOL=/usr/bin/libtool
LD_OLD=$LD
LD=$LD_FOR_BUILD
LDFLAGS_OLD=$LDFLAGS
LDFLAGS=""
wget https://gmplib.org/download/gmp/gmp-6.1.2.tar.bz2
tar -xvf gmp-6.1.2.tar.bz2
cd gmp-6.1.2
CC=$CC_FOR_BUILD CXX=$CXX_FOR_BUILD ./configure --enable-cxx --enable-shared
LD=$LD_FOR_BUILD LDFLAGS="" CC=$CC_FOR_BUILD CXX=$CXX_FOR_BUILD make -j${nproc}
make install
CC=$CC_OLD
CXX=$CXX_OLD
LIBTOOL=$LIBTOOL_OLD
LD=$LD_OLD
LDFLAGS=$LDFLAGS_OLD
cd $WORKSPACE/srcdir
export CPP_FLAGS=-I$prefix/include
export LD_LIBRARY_PATH=$target/lib:$LD_LIBRARY_PATH
export LDFLAGS=-Wl,-rpath,$prefix/lib
cd $WORKSPACE/srcdir
cd ntl-10.5.0/
cd src
./configure PREFIX=$prefix DEF_PREFIX=$prefix SHARED=on NTL_THREADS=off NTL_EXCEPTIONS=off NTL_GMP_LIP=on CXXFLAGS="-I$prefix/include -march=core2" TUNE=x86 CXX_FOR_BUILD="$CXX_FOR_BUILD" LD_FOR_BUILD="$LD_FOR_BUILD" CXX="$CXX" HOST=$target 
make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    MacOS(:x86_64),
    Linux(:x86_64, libc=:glibc)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libntl", Symbol(""))
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaMath/GMPBuilder/releases/download/v6.1.2-2/build_GMP.v6.1.2.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

