FROM sitespeedio/visualmetrics-deps:ffmpeg-3.4.2-imagemagick-6.9.7-5

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ENV FIREFOX_VERSION 58.0
ENV CHROME_VERSION 66.*
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
# Avoid ERROR: invoke-rc.d: unknown initscript, /etc/init.d/systemd-logind not found.

RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d && \
  touch /etc/init.d/systemd-logind

# touch
# Adding sudo for Throttle, lets see if we can find a better place (needed in Ubuntu 17)

# fonts-ipafont-gothic fonts-ipafont-mincho # jp (Japanese) fonts, install seems to solve missing Chinese hk/tw fonts as well.
# ttf-wqy-microhei fonts-wqy-microhei       # kr (Korean) fonts
# fonts-tlwg-loma fonts-tlwg-loma-otf       # th (Thai) fonts
# firefox-locale-hi fonts-gargi		    # Hindi (for now)

RUN apt-get update && apt-get install -y software-properties-common

RUN fonts='fonts-ipafont-gothic fonts-ipafont-mincho ttf-wqy-microhei fonts-wqy-microhei fonts-tlwg-loma fonts-tlwg-loma-otf firefox-locale-hi fonts-gargi' && \
  buildDeps='bzip2 wget' && \
  xvfbDeps='xvfb libgl1-mesa-dri xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic dbus-x11' && \
  add-apt-repository -y ppa:ubuntu-mozilla-daily/ppa && \ 
  apt-get update && \
  apt-get install -y $buildDeps --no-install-recommends && \
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
  apt-get update && \
  apt-get install -y \
  android-tools-adb \
  ca-certificates \
  x11vnc \
  sudo \
  iproute2 \
  # firefox-trunk \
  $fonts \
  $xvfbDeps \
  --no-install-recommends && \
  wget https://ftp.mozilla.org/pub/firefox/nightly/2018/04/2018-04-26-22-01-44-mozilla-central/firefox-61.0a1.en-US.linux-x86_64.tar.bz2 && \
  tar -xjf firefox-61.0a1.en-US.linux-x86_64.tar.bz2 && \
  mv firefox /opt/ && \
  ln -s /usr/bin/firefox-trunk /usr/local/bin/firefox && \
  apt-get purge -y --auto-remove $buildDeps && \
  apt-get install -y google-chrome-stable=${CHROME_VERSION} && \
  apt-get clean autoclean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
