FROM golang:1.12-alpine3.10

ENV OPENCV_VERSION=4.1.1
ENV BUILD="ca-certificates \
         git \
         build-base \
         musl-dev \
         alpine-sdk \
         make \
         g++ \
         gcc \
         libc-dev \
         linux-headers \
         libjpeg-turbo \
         libpng \
         tiff \
         openblas"

ENV DEV="clang clang-dev cmake pkgconf \
         openblas-dev libjpeg-turbo-dev \
         libpng-dev tiff-dev \
         "

ENV IMG_MAGICK_BUILD="build-base gcc git wget pkgconfig"
ENV IMG_MAGICK_DEV="jpeg-dev tiff-dev \
         giflib-dev libx11-dev"

ENV PKG_CONFIG_PATH /usr/local/lib64/pkgconfig
ENV LD_LIBRARY_PATH /usr/local/lib64
ENV CGO_CPPFLAGS -I/usr/local/include
ENV CGO_CXXFLAGS "--std=c++1z"
ENV CGO_LDFLAGS "-L/usr/local/lib -lopencv_core -lopencv_face -lopencv_imgproc -lopencv_imgcodecs"
ENV IMAGEMAGICK_VERSION=6.9.10-65
ENV UFRAW_VERSION="0.22"
COPY ufraw.patch /
RUN apk update && \
    apk add --no-cache ${BUILD} ${DEV} ${IMG_MAGICK_DEV} glib-dev lcms2-dev patch && \
    apk add --virtual build-dependencies ${IMG_MAGICK_BUILD} && \
    mkdir /tmp/opencv && \
    cd /tmp/opencv && \
    wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    unzip opencv.zip && \
    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \
    unzip opencv_contrib.zip && \
    mkdir /tmp/opencv/opencv-${OPENCV_VERSION}/build && cd /tmp/opencv/opencv-${OPENCV_VERSION}/build && \
    cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D OPENCV_EXTRA_MODULES_PATH=/tmp/opencv/opencv_contrib-${OPENCV_VERSION}/modules \
    -D INSTALL_C_EXAMPLES=NO \
    -D INSTALL_PYTHON_EXAMPLES=NO \
    -D BUILD_ANDROID_EXAMPLES=NO \
    -D BUILD_DOCS=NO \
    -D BUILD_TESTS=NO \
    -D BUILD_PERF_TESTS=NO \
    -D BUILD_EXAMPLES=NO \
    -D WITH_JASPER=OFF \
    -D WITH_FFMPEG=NO \
    -D BUILD_opencv_java=NO \
    -D BUILD_opencv_python=NO \
    -D BUILD_opencv_python2=NO \
    -D BUILD_opencv_python3=NO \
    -D OPENCV_GENERATE_PKGCONFIG=YES .. && \
    make -j4 && \
    make install && \
    cd && rm -rf /tmp/opencv && \
    go get -u -d gocv.io/x/gocv && go run ${GOPATH}/src/gocv.io/x/gocv/cmd/version/main.go && \
    cd && \
	wget https://github.com/ImageMagick/ImageMagick6/archive/${IMAGEMAGICK_VERSION}.tar.gz && \
	tar xvzf ${IMAGEMAGICK_VERSION}.tar.gz && \
	cd ImageMagick* && \
	./configure \
	    --without-magick-plus-plus \
	    --without-perl \
	    --disable-openmp \
	    --with-gvc=no \
	    --disable-docs && \
	make -j$(nproc) && make install && \
	ldconfig /usr/local/lib && \
    cd && rm -rf ImageMagick* && \
    curl -s --fail -L https://sourceforge.net/projects/ufraw/files/ufraw/ufraw-${UFRAW_VERSION}/ufraw-${UFRAW_VERSION}.tar.gz/download | tar -C /opt -xz && \
    patch /opt/ufraw-${UFRAW_VERSION}/dcraw.cc /ufraw.patch && \
    cd /opt/ufraw-${UFRAW_VERSION} && \
    ./configure --prefix=/usr/local --disable-dependency-tracking --without-gtk --without-gimp && \
    make && \
    make install && \
    cd / && \
    rm -rf /opt/ufraw-${UFRAW_VERSION} && \
    apk del ${DEV_DEPS} && \
    apk del build-dependencies  && \
    rm -rf /var/cache/apk/*