FROM sitespeedio/visualmetrics-deps

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ENV FIREFOX_VERSION 49.0*
ENV CHROME_VERSION 54.0.*

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Avoid ERROR: invoke-rc.d: unknown initscript, /etc/init.d/systemd-logind not found.
RUN touch /etc/init.d/systemd-logind

# Adding sudo for SLTC, lets see if we can find a better place (needed in Ubuntu 16)

RUN \
apt-get update && \
apt-get install -y wget sudo && \
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
apt-get update && \
apt-get install -y \
ca-certificates \
libgl1-mesa-dri \
xfonts-100dpi \
xfonts-75dpi \
xfonts-scalable \
xfonts-cyrillic \
xvfb --no-install-recommends && \
apt-get purge -y wget && \
apt-get install -y google-chrome-stable=${CHROME_VERSION} && \
apt-get install -y firefox=${FIREFOX_VERSION} --no-install-recommends && \
apt-get clean autoclean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
