
BUILD_PREFIX="${BUILD_PREFIX:-/usr/local}"
DSDP_VERSION="5.8"
DSDP_SHA256="26aa624525a636de272c0b329e2dfd01a0d5b7827f1c1c76f393d71e37dead70"
GLPK_VERSION="4.65"
GLPK_SHA256="4281e29b628864dfe48d393a7bedd781e5b475387c20d8b0158f329994721a10"
GSL_VERSION="2.6"
GSL_SHA256="b782339fc7a38fe17689cb39966c4d821236c28018b6593ddb6fd59ee40786a8"
FFTW_VERSION="3.3.8"
FFTW_SHA256="6113262f6e92c5bd474f2875fa1b01054c4ad5040f6b0da7c03c98821d9ae303"
SUITESPARSE_VERSION="5.7.2"
SUITESPARSE_SHA256="fe3bc7c3bd1efdfa5cffffb5cebf021ff024c83b5daf0ab445429d3d741bd3ad"
OSQP_VERSION="0.6.2"


type fetch_unpack &> /dev/null || source multibuild/library_builders.sh

function get_cmake_320 {
  # Install cmake == 3.2
  local cmake=cmake
  if [ -n "$IS_MACOS" ]; then
    brew install cmake > /dev/null
  else
    curl -L -o cmake.sh https://github.com/Kitware/CMake/releases/download/v3.20.0/cmake-3.20.0-linux-x86_64.sh
    sh cmake.sh --prefix=/usr/local/ --exclude-subdir
  fi
  echo $cmake
}

function build_dsdp {
  if [ -e dsdp-stamp ]; then return; fi
  fetch_unpack http://www.mcs.anl.gov/hs/software/DSDP/DSDP${DSDP_VERSION}.tar.gz
  check_sha256sum archives/DSDP${DSDP_VERSION}.tar.gz ${DSDP_SHA256}
  if [ -n "${IS_OSX}" ]; then
    (cd DSDP${DSDP_VERSION} \
        && patch -p1 < ../dsdp.patch \
        && make PREFIX=${BUILD_PREFIX} IS_OSX=1 DSDPROOT=`pwd` install)
  else
    build_openblas
    (cd DSDP${DSDP_VERSION} \
        && patch -p1 < ../dsdp.patch \
        && make LAPACKBLAS="-L${BUILD_PREFIX}/lib -lopenblas" PREFIX=${BUILD_PREFIX} DSDPROOT=`pwd` install)
  fi
  touch dsdp-stamp
}

function build_fftw {
  if [ -e fftw-stamp ]; then return; fi
  if [ -n "${IS_OSX}" ]; then
      brew install fftw
  else
  fetch_unpack http://www.fftw.org/fftw-${FFTW_VERSION}.tar.gz
  check_sha256sum archives/fftw-${FFTW_VERSION}.tar.gz ${FFTW_SHA256}
  (cd fftw-${FFTW_VERSION} \
      && ./configure --prefix=${BUILD_PREFIX} --enable-shared \
      && make \
      && make install)
fi
  touch fftw-stamp
}

function build_glpk {
  if [ -e glpk-stamp ]; then return; fi
  if [ -n "${IS_OSX}" ]; then
      brew install glpk
  else
  fetch_unpack http://ftp.gnu.org/gnu/glpk/glpk-${GLPK_VERSION}.tar.gz
  check_sha256sum archives/glpk-${GLPK_VERSION}.tar.gz ${GLPK_SHA256}
  (cd glpk-${GLPK_VERSION} \
      && ./configure --prefix=${BUILD_PREFIX} \
      && make \
      && make install)
fi
  touch glpk-stamp
}

function build_gsl {
  if [ -e gsl-stamp ]; then return; fi
  if [ -n "${IS_OSX}" ]; then
      brew install gsl
  else
  fetch_unpack http://ftp.download-by.net/gnu/gnu/gsl/gsl-${GSL_VERSION}.tar.gz
  check_sha256sum archives/gsl-${GSL_VERSION}.tar.gz ${GSL_SHA256}
  (cd gsl-${GSL_VERSION} \
      && ./configure --prefix=${BUILD_PREFIX} \
      && make \
      && make install)
fi
  touch gsl-stamp
}

function build_osqp {
  if [ -e osqp-stamp ]; then return; fi
  if [ -n "${IS_OSX}" ]; then
      brew install osqp
  else
    get_modern_cmake
    git clone --recursive https://github.com/oxfordcontrol/osqp.git
    (cd osqp \
        && git checkout v${OSQP_VERSION} \
        && mkdir build \
        && cd build \
        && cmake -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX .. \
        && cmake --build . --target install)
fi
  touch osqp-stamp
}
