# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

# Configure which optional extensions to build
export KVXOPT_BUILD_DSDP=0
export KVXOPT_BUILD_FFTW=1
export KVXOPT_BUILD_GLPK=1
export KVXOPT_BUILD_GSL=1
export KVXOPT_BUILD_OSQP=1
export OPENBLAS_VERSION=0.3.13
TESTS_DIR="$(pwd)/cvxopt/tests"

source library_builders.sh

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.

    # Download SuiteSparse
    if [ ! -e suitesparse-stamp ]; then
        mkdir -p archives
        curl -L https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v${SUITESPARSE_VERSION}.tar.gz > archives/SuiteSparse-${SUITESPARSE_VERSION}.tar.gz
        check_sha256sum archives/SuiteSparse-${SUITESPARSE_VERSION}.tar.gz ${SUITESPARSE_SHA256}
        mkdir SuiteSparse && tar -xf archives/SuiteSparse-${SUITESPARSE_VERSION}.tar.gz -C SuiteSparse --strip-components 1
        touch suitesparse-stamp
    fi

    # Build dependencies
    if [ -z "${IS_OSX}" ]; then
        build_openblas  # defined in multibuild/library_builders.sh
        export KVXOPT_BLAS_LIB=openblas
        export KVXOPT_LAPACK_LIB=openblas
        export KVXOPT_BLAS_LIB_DIR=${BUILD_PREFIX}/lib
    fi
    if [ "${KVXOPT_BUILD_DSDP}" == "1" ]; then build_dsdp; fi
    if [ "${KVXOPT_BUILD_FFTW}" == "1" ]; then build_fftw; fi
    if [ "${KVXOPT_BUILD_GLPK}" == "1" ]; then build_glpk; fi
    if [ "${KVXOPT_BUILD_GSL}" == "1" ]; then build_gsl; fi
    if [ "${KVXOPT_BUILD_OSQP}" == "1" ]; then build_osqp; fi

    export KVXOPT_GLPK_LIB_DIR=${BUILD_PREFIX}/lib
    export KVXOPT_GLPK_INC_DIR=${BUILD_PREFIX}/include
    export KVXOPT_GSL_LIB_DIR=${BUILD_PREFIX}/lib
    export KVXOPT_GSL_INC_DIR=${BUILD_PREFIX}/include/gsl
    export KVXOPT_FFTW_LIB_DIR=${BUILD_PREFIX}/lib
    export KVXOPT_FFTW_INC_DIR=${BUILD_PREFIX}/include
    export KVXOPT_DSDP_LIB_DIR=${BUILD_PREFIX}/lib
    export KVXOPT_DSDP_INC_DIR=${BUILD_PREFIX}/include
    export KVXOPT_OSQP_LIB_DIR=${BUILD_PREFIX}/lib
    export KVXOPT_OSQP_INC_DIR=${BUILD_PREFIX}/include
    export KVXOPT_SUITESPARSE_SRC_DIR=`pwd`/SuiteSparse
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    python --version
    python -c 'from cvxopt import blas,lapack,cholmod,umfpack, klu'
    if [ "${KVXOPT_BUILD_DSDP}" == "1" ]; then python -c 'from cvxopt import dsdp'; fi
    if [ "${KVXOPT_BUILD_FFTW}" == "1" ]; then python -c 'from cvxopt import fftw'; fi
    if [ "${KVXOPT_BUILD_GLPK}" == "1" ]; then python -c 'from cvxopt import glpk'; fi
    if [ "${KVXOPT_BUILD_GSL}" == "1" ]; then python -c 'from cvxopt import gsl'; fi
    if [ "${KVXOPT_BUILD_OSQP}" == "1" ]; then python -c 'from cvxopt import osqp'; fi
    pytest ${TESTS_DIR}
}
