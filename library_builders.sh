DSDP_VERSION="5.8"
DSDP_SHA256="26aa624525a636de272c0b329e2dfd01a0d5b7827f1c1c76f393d71e37dead70"
GLPK_VERSION="5.0"
GLPK_SHA256="4a1013eebb50f728fc601bdd833b0b2870333c3b3e5a816eeba921d95bec6f15"
GSL_VERSION="2.7"
GSL_SHA256="efbbf3785da0e53038be7907500628b466152dbc3c173a87de1b5eba2e23602b"
FFTW_VERSION="3.3.8"
FFTW_SHA256="6113262f6e92c5bd474f2875fa1b01054c4ad5040f6b0da7c03c98821d9ae303"
SUITESPARSE_VERSION="7.8.2"
SUITESPARSE_SHA256="996c48c87baaeb5fc04bd85c7e66d3651a56fe749c531c60926d75b4db5d2181"
OSQP_VERSION="0.6.3"
OPENBLAS_VERSION="0.3.23"
OPENBLAS_SHA256="0484d275f87e9b8641ff2eecaa9df2830cbe276ac79ad80494822721de6e1693"

OPENBLAS_LIB_URL_OSX="https://anaconda.org/multibuild-wheels-staging/openblas-libs"
OPENBLAS_VERSION_OSX="0.3.23"
OPENBLAS_VERSION_OSX_x86_64="246-g3d31191b"
OPENBLAS_POSTFIX_OSX_x86_64="macosx_10_9_x86_64-gf_c469a42"
OPENBLAS_VERSION_OSX_arm64="246-g3d31191b"
OPENBLAS_POSTFIX_OSX_arm64="macosx_11_0_arm64-gf_5272328"



type fetch_unpack &> /dev/null || source multibuild/library_builders.sh



function build_dsdp {
  if [ -e dsdp-stamp ]; then return; fi
  fetch_unpack http://www.mcs.anl.gov/hs/software/DSDP/DSDP${DSDP_VERSION}.tar.gz
  check_sha256sum archives/DSDP${DSDP_VERSION}.tar.gz ${DSDP_SHA256}
  if [  -n "${IS_MACOS}" ]; then
    (cd DSDP${DSDP_VERSION} \
        && patch -p1 < ../dsdp.patch \
        && make PREFIX=${BUILD_PREFIX} IS_OSX=1 DSDPROOT=`pwd` install)
  else
    build_openblas
    (cd DSDP${DSDP_VERSION} \
        && patch -p1 < ../dsdp.patch \
        && make LAPACKBLAS="-L${BUILD_PREFIX}/lib -lopenblas" PREFIX=${BUILD_PREFIX} DSDPROOT=`pwd` install)
  fi
  export KVXOPT_DSDP_LIB_DIR=${BUILD_PREFIX}/lib
  export KVXOPT_DSDP_INC_DIR=${BUILD_PREFIX}/include
  touch dsdp-stamp
}

function openblas_get_osx {
    # Get an openblas compiled library from
    # https://anaconda.org/multibuild-wheels-staging/openblas-libs
    # The general form of the link is (under the URL above)
    # URL/v0.3.10/downloads/openblas-v0.3.10-manylinux2010_x86_64.tar.gz
    # https://anaconda.org/multibuild-wheels-staging/openblas-libs/v0.3.13-62-gaf2b0d02/download/openblas-v0.3.13-62-gaf2b0d02-macosx_11_0_arm64-gf_f26990f.tar.gz
    # https://anaconda.org/multibuild-wheels-staging/openblas-libs/v0.3.15-62-gaf2b0d02/download/openblas64_-v0.3.15-62-gaf2b0d02-macosx_10_9_x86_64-gf_1becaaa.tar.gz
    # https://anaconda.org/multibuild-wheels-staging/openblas-libs/v0.3.13-62-gaf2b0d02/download/openblas64_-v0.3.13-62-gaf2b0d02-macosx_10_9_x86_64-gf_1becaaa.tar.gz
    local plat=${1:-$}
    # qual could be 64 to get a 64-bit version
    local qual=$2

    if [ "$PLAT" == "arm64" ]; then
      local platix=$OPENBLAS_VERSION_OSX_arm64-$OPENBLAS_POSTFIX_OSX_arm64
      local folder=v$OPENBLAS_VERSION_OSX-$OPENBLAS_VERSION_OSX_arm64
      local prefix=openblas-v$OPENBLAS_VERSION_OSX

    else
      local platix=$OPENBLAS_VERSION_OSX_x86_64-$OPENBLAS_POSTFIX_OSX_x86_64
      local folder=v$OPENBLAS_VERSION_OSX-$OPENBLAS_VERSION_OSX_x86_64
      local prefix=openblas-v$OPENBLAS_VERSION_OSX

    fi


    local fname="$prefix-$platix.tar.gz"

    local out_fname="${ARCHIVE_SDIR}/$fname"
    if [ ! -e "$out_fname" ]; then
        local webname=${OPENBLAS_LIB_URL_OSX}/$folder/download/${fname}
        curl -L "$webname" > $out_fname || exit 1
        # make sure it is not an HTML document of download failure
        local ok=$(file $out_fname | grep "HTML document")
        if [ -n "$ok" ]; then
            echo Fetching "${OPENBLAS_LIB_URL_OSX}/$fname" failed;
            exit 1;
        fi
    fi
    echo "$out_fname"
}

function build_openblas_osx2 {
    if [ -e openblas-stamp ]; then return; fi

    mkdir -p $ARCHIVE_SDIR
    local plat=${1:-${PLAT:-x86_64}}
    local tar_path=$(abspath $(openblas_get_osx $plat))
    (cd / \
     && tar xzvf $tar_path \
     && pwd && ls)

    touch openblas-stamp
}


function build_fftw {
  if [ -e fftw-stamp ]; then return; fi

  if [ -n "$IS_MACOS" ]; then
    brew install glpk
    brew link --force glpk
    export KVXOPT_FFTW_INC_DIR=$(brew --prefix)/include
    export KVXOPT_FFTW_LIB_DIR=$(brew --prefix)/lib
  else

    fetch_unpack http://www.fftw.org/fftw-${FFTW_VERSION}.tar.gz
    check_sha256sum archives/fftw-${FFTW_VERSION}.tar.gz ${FFTW_SHA256}
    (cd fftw-${FFTW_VERSION} \
        && ./configure --prefix=${BUILD_PREFIX} --enable-shared \
        && make \
        && make install \
        && cd .. \
        && rm -rf fftw-${FFTW_VERSION})
    export KVXOPT_FFTW_INC_DIR=${BUILD_PREFIX}/include
    export KVXOPT_FFTW_LIB_DIR=${BUILD_PREFIX}/lib
  fi
  touch fftw-stamp
}

function build_glpk {
  if [ -e glpk-stamp ]; then return; fi

  if [ -n "$IS_MACOS" ]; then
      brew install glpk
      brew link --force glpk
      export KVXOPT_GLPK_INC_DIR=$(brew --prefix)/include
      export KVXOPT_GLPK_LIB_DIR=$(brew --prefix)/lib
  else

    fetch_unpack http://ftp.gnu.org/gnu/glpk/glpk-${GLPK_VERSION}.tar.gz
    check_sha256sum archives/glpk-${GLPK_VERSION}.tar.gz ${GLPK_SHA256}
    (cd glpk-${GLPK_VERSION} \
        && ./configure --prefix=${BUILD_PREFIX} \
        && make \
        && make install \
        && cd .. \
        && rm -rf glpk-${GLPK_VERSION})
    export KVXOPT_GLPK_INC_DIR=${BUILD_PREFIX}/include
    export KVXOPT_GLPK_LIB_DIR=${BUILD_PREFIX}/lib
  fi
  touch glpk-stamp
}

function build_gsl {
  if [ -e gsl-stamp ]; then return; fi


  if [ -n "$IS_MACOS" ]; then
      brew install gsl
      brew link --force gsl
      export KVXOPT_GSL_INC_DIR=$(brew --prefix)/include
      export KVXOPT_GSL_LIB_DIR=$(brew --prefix)/lib
  else

   fetch_unpack https://mirror.ibcp.fr/pub/gnu/gsl/gsl-${GSL_VERSION}.tar.gz
   check_sha256sum archives/gsl-${GSL_VERSION}.tar.gz ${GSL_SHA256}
    (cd gsl-${GSL_VERSION} \
    && ./configure --prefix=${BUILD_PREFIX}\
    && make \
    && make install \
    && cd .. \
    && rm -rf gsl-${GSL_VERSION})
    export KVXOPT_GSL_INC_DIR=${BUILD_PREFIX}/include
    export KVXOPT_GSL_LIB_DIR=${BUILD_PREFIX}/lib
  fi;


  touch gsl-stamp
}

function build_osqp {
  if [ -e osqp-stamp ]; then return; fi


  get_modern_cmake
  git clone --recursive https://github.com/oxfordcontrol/osqp.git
  (cd osqp \
      && git checkout v${OSQP_VERSION} \
      && git submodule sync --recursive \
      && git -c protocol.version=2 submodule update --init --force --depth=1 --recursive \
      && mkdir build \
      && cd build \
      && cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX .. \
      && cmake --build . --target install \
      && cd ../.. \
      && rm -rf osqp)
  export KVXOPT_OSQP_INC_DIR=${BUILD_PREFIX}/include/osqp
  export KVXOPT_OSQP_LIB_DIR=${BUILD_PREFIX}/lib

}
