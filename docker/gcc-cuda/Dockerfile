# The Nvidia stages of this Dockerfile was obtained from:
# https://gitlab.com/nvidia/container-images/cuda/-/tree/master/dist/centos7/10.1 
# Only the 1st line was modified to use centos 7.6 instead of 7.7
# (Nvidia Dockerfiles only provide latest version of centos 7) 
FROM centos:7.6.1810 AS nvidia-base

RUN NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/7fa2af80.pub | sed '/^Version/d' > /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA && \
    echo "$NVIDIA_GPGKEY_SUM  /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA" | sha256sum -c --strict -

COPY /docker/gcc-cuda/cuda.repo /etc/yum.repos.d/cuda.repo

ENV CUDA_VERSION 10.1.243

ENV CUDA_PKG_VERSION 10-1-$CUDA_VERSION-1
# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN yum install -y \
    cuda-cudart-$CUDA_PKG_VERSION \
    cuda-compat-10-1 \
    && \
    ln -s cuda-10.1 /usr/local/cuda && \
    rm -rf /var/cache/yum/*

# nvidia-docker 1.0
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.1 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411"


FROM nvidia-base AS nvidia-runtime 

RUN yum install -y \
    cuda-libraries-$CUDA_PKG_VERSION \
    cuda-nvtx-$CUDA_PKG_VERSION \
    libcublas10-10.2.1.243-1 \
    && \
    rm -rf /var/cache/yum/*


FROM nvidia-runtime AS nvidia-develop 

RUN yum install -y \
    cuda-nvml-dev-$CUDA_PKG_VERSION \
    cuda-command-line-tools-$CUDA_PKG_VERSION \
    cuda-libraries-dev-$CUDA_PKG_VERSION \
    cuda-minimal-build-$CUDA_PKG_VERSION \
    libcublas-devel-10.2.1.243-1 \
    && \
    rm -rf /var/cache/yum/*

ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs


ARG TMP_DIR=/tmp
FROM nvidia-develop AS tpl_toolchain_intersect_geosx_toolchain

ENV GEOSX_TPL_DIR=/opt/GEOSX_TPL

# Using gcc 8.3.1 provided by the Software Collections (SCL).
RUN yum install -y \
    centos-release-scl \
    && yum install -y \
    devtoolset-8-gcc \
    devtoolset-8-gcc-c++ \
    devtoolset-8-gcc-gfortran

# Installing latest CMake version available on Lassen
ARG CMAKE_VERSION=3.14.5
RUN curl -fsSL https://cmake.org/files/v${CMAKE_VERSION%.[0-9]*}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz | tar --directory=/usr/local --strip-components=1 -xzf -

# Installing dependencies
RUN yum -y install \
    make \
    tbb \
    blas-devel \
    lapack-devel \
    zlib-devel \
    openmpi-devel \
    python

ENV CC=/opt/rh/devtoolset-8/root/usr/bin/gcc \
    CXX=/opt/rh/devtoolset-8/root/usr/bin/g++ \
    MPICC=/usr/lib64/openmpi/bin/mpicc \
    MPICXX=/usr/lib64/openmpi/bin/mpicxx \
    MPIEXEC=/usr/lib64/openmpi/bin/mpirun
ENV OMPI_CC=${CC} \
    OMPI_CXX=${CXX} 
ENV ENABLE_CUDA=ON \
    CMAKE_CUDA_FLAGS="-restrict -arch sm_70 --expt-extended-lambda -Werror cross-execution-space-call,reorder,deprecated-declarations"

# Installing TPL's
FROM tpl_toolchain_intersect_geosx_toolchain AS tpl_toolchain

ENV FC=/opt/rh/devtoolset-8/root/usr/bin/gfortran \
    MPIFC=/usr/lib64/openmpi/bin/mpifort
ENV OMPI_FC=${FC}

RUN yum install -y \
    tbb-devel \
    bc \
    file \
    bison \
    flex \
    patch

ARG TMP_DIR
ARG TPL_SRC_DIR=${TMP_DIR}/thirdPartyLibs
ARG TPL_BUILD_DIR=${TMP_DIR}/build

ARG CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda
ARG CUDA_ARCH=sm_70
ARG CMAKE_CUDA_COMPILER=${CUDA_TOOLKIT_ROOT_DIR}/bin/nvcc

COPY . ${TPL_SRC_DIR}
RUN ${TPL_SRC_DIR}/docker/configure_tpl_build.sh \
    -DENABLE_CUDA=${ENABLE_CUDA} \
    -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_TOOLKIT_ROOT_DIR} \
    -DCUDA_ARCH=${CUDA_ARCH} \
    -DCMAKE_CUDA_COMPILER=${CMAKE_CUDA_COMPILER}
WORKDIR ${TPL_BUILD_DIR}
RUN make

# Extract only TPL's from previous stage
FROM tpl_toolchain_intersect_geosx_toolchain AS geosx_toolchain

COPY --from=tpl_toolchain ${GEOSX_TPL_DIR} ${GEOSX_TPL_DIR}

RUN yum install -y \
    openssh-client \
    texlive \
    graphviz \
    git
