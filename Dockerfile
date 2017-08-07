FROM resin/raspberry-pi-python:3

ENV LIBCEC_VERSION=4.0.2 P8_PLATFORM_VERSION=2.1.0.1

WORKDIR /root

ADD https://github.com/Pulse-Eight/libcec/archive/libcec-${LIBCEC_VERSION}.tar.gz https://github.com/Pulse-Eight/platform/archive/p8-platform-${P8_PLATFORM_VERSION}.tar.gz ./

RUN apt-get -qqy update \
 && apt-get -qqy install cmake libudev-dev libxrandr-dev python-dev swig \
 && rm -rf /var/cache/apk/* \
# Userland
 && curl -L https://api.github.com/repos/raspberrypi/userland/tarball | tar xvz \
 && cd raspberrypi-userland* \
 && ./buildme \
# Platform
 && PYTHON_LIBDIR=$(python -c 'from distutils import sysconfig; print(sysconfig.get_config_var("LIBDIR"))') \
 && PYTHON_LDLIBRARY=$(python -c 'from distutils import sysconfig; print(sysconfig.get_config_var("LDLIBRARY"))') \
 && PYTHON_LIBRARY="${PYTHON_LIBDIR}/${PYTHON_LDLIBRARY}" \
 && PYTHON_INCLUDE_DIR=$(python -c 'from distutils import sysconfig; print(sysconfig.get_python_inc())') \
 && cd \
 && tar xvzf p8-platform-${P8_PLATFORM_VERSION}.tar.gz && rm p8-platform-*.tar.gz && mv platform* platform \
 && mkdir platform/build \
 && cd platform/build \
 && cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr \
   .. \
 && make \
 && make install \
# Libcec
 && cd \
 && tar xvzf libcec-${LIBCEC_VERSION}.tar.gz && rm libcec-*.tar.gz && mv libcec* libcec \
 && mkdir libcec/build \
 && cd libcec/build \
 && cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr \
   -DRPI_INCLUDE_DIR=/opt/vc/include \
   -DRPI_LIB_DIR=/opt/vc/lib \
   -DPYTHON_LIBRARY="${PYTHON_LIBRARY}" \
   -DPYTHON_INCLUDE_DIR="${PYTHON_INCLUDE_DIR}" \
   .. \
 && make -j4 \
 && make install \
# Cleanup
 && cd \
 && rm -rf platform libcec raspberrypi-userland*

ENV LD_LIBRARY_PATH=/opt/vc/lib:${LD_LIBRARY_PATH}
