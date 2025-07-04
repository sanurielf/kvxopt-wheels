# Define custom utilities
if [ $(uname) == "Linux" ]; then IS_LINUX=1; fi
# For verbosity: report where each command came from
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -x


# Configure which optional extensions to build
export KVXOPT_BUILD_DSDP=0
export KVXOPT_BUILD_FFTW=0
export KVXOPT_BUILD_GLPK=1
export KVXOPT_BUILD_GSL=1
export OPENBLAS_VERSION=0.3.13

# OSQP cannot be build in manylinux1 because Cmake>=3.2
if [ -z "$IS_MACOS" -a "${MB_ML_VER}" == "1" ]; then
    export KVXOPT_BUILD_OSQP=0
else
    export KVXOPT_BUILD_OSQP=1
fi

# GSL and GLPK cannot be build in linux aarch64 because it takes more
# than 1 hour to compile. This is because of QEMU docker virtualization from
# x_86_64 to arm 64
if [ "$PLAT" == "aarch64" ]; then
    export KVXOPT_BUILD_GSL=0
    export KVXOPT_BUILD_GLPK=0
fi

# Work around https://github.com/pypa/manylinux/issues/1309
if [ $(uname) == "Linux" ]; then
    ! git config --global --add safe.directory /io/kvxopt
fi


ROOT_DIR=$(dirname $(dirname "${BASH_SOURCE[0]}"))
source ${ROOT_DIR}/multibuild/common_utils.sh
source ${ROOT_DIR}/gfortran-install/gfortran_utils.sh


TESTS_DIR="$(pwd)/kvxopt/tests"

source library_builders.sh

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.

    # Download SuiteSparse
    # if [ ! -e suitesparse-stamp ]; then
    #     mkdir -p archives
    #     curl -L https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v${SUITESPARSE_VERSION}.tar.gz > archives/SuiteSparse-${SUITESPARSE_VERSION}.tar.gz
    #     check_sha256sum archives/SuiteSparse-${SUITESPARSE_VERSION}.tar.gz ${SUITESPARSE_SHA256}
    #     mkdir SuiteSparse && tar -xf archives/SuiteSparse-${SUITESPARSE_VERSION}.tar.gz -C SuiteSparse --strip-components 1
    #     touch suitesparse-stamp
    # fi
    # export KVXOPT_SUITESPARSE_SRC_DIR=`pwd`/SuiteSparse


    build_suitesparse
    if [ -n "$IS_MACOS" ]; then
        export KVXOPT_SUITESPARSE_INC_DIR=$(brew --prefix)/include/suitesparse
        export KVXOPT_SUITESPARSE_LIB_DIR=$(brew --prefix)/lib
    else
        export KVXOPT_SUITESPARSE_INC_DIR=/usr/include/suitesparse
        export KVXOPT_SUITESPARSE_LIB_DIR=/usr/lib64
    fi

    # Build dependencies
    build_openblas
    export KVXOPT_BLAS_LIB=openblas
    export KVXOPT_LAPACK_LIB=openblas
    if [ -n "$IS_MACOS" ]; then
        export KVXOPT_BLAS_LIB_DIR=/usr/local/opt/openblas/lib
    else
        export KVXOPT_BLAS_LIB_DIR=${BUILD_PREFIX}/lib
    fi

    export KVXOPT_GSL_LIB_DIR=${BUILD_PREFIX}/lib



    if [ "${KVXOPT_BUILD_GSL}" == "1" ]; then build_gsl; fi
    if [ "${KVXOPT_BUILD_OSQP}" == "1" ]; then build_osqp; fi
    if [ "${KVXOPT_BUILD_DSDP}" == "1" ]; then build_dsdp; fi
    if [ "${KVXOPT_BUILD_FFTW}" == "1" ]; then build_fftw; fi
    if [ "${KVXOPT_BUILD_GLPK}" == "1" ]; then build_glpk; fi


    if [ -n "${IS_MACOS}" ]; then
        export DYLD_LIBRARY_PATH="${BUILD_PREFIX}/lib/:$DYLD_LIBRARY_PATH"
        export MACOSX_DEPLOYMENT_TARGET=14.0
    fi
}


function run_tests {

    # Runs tests on installed distribution from an empty directory
    $PYTHON_EXE --version
    $PYTHON_EXE -c 'from kvxopt import blas,lapack,cholmod,umfpack,klu'
    pytest ${TESTS_DIR}
}
