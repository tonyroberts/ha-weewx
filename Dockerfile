ARG BUILD_FROM
FROM $BUILD_FROM

ARG WEEWX_UID=421
ARG WEEWX_VERSION=4.10.2
ARG WEEWX_HOME="/home/weewx"
ARG WEEWX_ARCHIVE="weewx-${WEEWX_VERSION}.tar.gz"

RUN adduser --system syslog
RUN adduser --system sysllog

WORKDIR /tmp

COPY rootfs /
COPY requirements.txt /tmp/
COPY logger.patch /tmp/

RUN addgroup --system --gid ${WEEWX_UID} weewx \
  && adduser --system --uid ${WEEWX_UID} --ingroup weewx weewx

RUN apk add wget gpg patch

RUN mkdir -p /etc/apt/trusted.gpg.d
RUN mkdir -p /etc/apt/sources.list.d

RUN wget -qO - https://weewx.com/keys.html | gpg --dearmor --output /etc/apt/trusted.gpg.d/weewx.gpg
RUN wget -qO - https://weewx.com/apt/weewx-python3.list | tee /etc/apt/sources.list.d/weewx.list

RUN wget -O "${WEEWX_ARCHIVE}" "https://weewx.com/downloads/released_versions/${WEEWX_ARCHIVE}"
RUN wget -O weewx-mqtt.zip https://github.com/matthewwall/weewx-mqtt/archive/master.zip
RUN wget -O weewx-interceptor.zip https://github.com/matthewwall/weewx-interceptor/archive/master.zip

RUN mkdir -p /tmp/weewx-src
RUN tar xvz --directory /tmp/weewx-src --strip-components=1 --file "${WEEWX_ARCHIVE}"

WORKDIR "/tmp/weewx-src"

RUN patch ./bin/weeutil/logger.py < /tmp/logger.patch
RUN rm ./bin/six.py

RUN pip3 install -r /tmp/requirements.txt
RUN python3 ./setup.py build
RUN python3 ./setup.py install

WORKDIR ${WEEWX_HOME}

RUN chown -R weewx:weewx ${WEEWX_HOME}

RUN python3 ./bin/wee_extension --install /tmp/weewx-mqtt.zip
RUN python3 ./bin/wee_extension --install /tmp/weewx-interceptor.zip
