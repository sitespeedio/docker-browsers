FROM sitespeedio/visualmetrics-deps:ffmpeg-4.2.2-imagemagick-6.9.10-23-p2-c

ARG TARGETPLATFORM

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ENV FIREFOX_VERSION 84.0
ENV CHROME_VERSION 88.*
ENV EDGE_VERSION 89.*
#ENV CHROME_BETA_VERSION 77.*

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
# Avoid ERROR: invoke-rc.d: unknown initscript, /etc/init.d/systemd-logind not found.

RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d && \
  touch /etc/init.d/systemd-logind

# Adding sudo for Throttle, lets see if we can find a better place (needed in Ubuntu 17)

# fonts-ipafont-gothic fonts-ipafont-mincho # jp (Japanese) fonts, install seems to solve missing Chinese hk/tw fonts as well.
# ttf-wqy-microhei fonts-wqy-microhei       # kr (Korean) fonts
# fonts-tlwg-loma fonts-tlwg-loma-otf       # th (Thai) fonts
# firefox-locale-hi fonts-gargi		    # Hindi (for now)

RUN fonts='fonts-ipafont-gothic fonts-ipafont-mincho ttf-wqy-microhei fonts-wqy-microhei fonts-tlwg-loma fonts-tlwg-loma-otf firefox-locale-hi fonts-gargi' && \
  buildDeps='bzip2 gnupg wget ca-certificates curl gpg' && \
  xvfbDeps='xvfb libgl1-mesa-dri xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic dbus-x11' && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y $buildDeps --no-install-recommends && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  android-tools-adb \
  ca-certificates \
  x11vnc \
  sudo \
  iproute2 \
  $fonts \
  $xvfbDeps \
  --no-install-recommends && \
  if [ "$TARGETPLATFORM" = "linux/amd64" ] ; \
    then \
      wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - ; \
      echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list ; \
      curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg ; \
      install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ ; \
      sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list' ; \
      rm microsoft.gpg  ; \
      apt-get update && \
      wget https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/en-US/firefox-${FIREFOX_VERSION}.tar.bz2 ; \
      tar -xjf firefox-${FIREFOX_VERSION}.tar.bz2 ; \
      rm firefox-${FIREFOX_VERSION}.tar.bz2 ; \
      mv firefox /opt/ ; \
      ln -s /opt/firefox/firefox /usr/local/bin/firefox ; \
      # Needed for when we install FF this way
      apt-get install -y libdbus-glib-1-2 ; \
      apt-get purge -y --auto-remove $buildDeps ; \
      apt-get install -y google-chrome-stable=${CHROME_VERSION} ; \
      apt-get install -y microsoft-edge-dev=${EDGE_VERSION}; \
    elif [  "$TARGETPLATFORM" = "linux/arm64" ]; \
	    then \
        apt-get -y install lsb-release libcairo2 libatk1.0-0 libcairo-gobject2 libdbus-glib-1-2 libgdk-pixbuf2.0-0 libgdk-pixbuf2.0-0 libgtk-3-0 libharfbuzz0b libpango-1.0-0 libxcb-shm0 libxcomposite1 libxcursor1 ; \
        wget https://launchpad.net/~ubuntu-mozilla-security/+archive/ubuntu/ppa/+build/20775771/+files/firefox_84.0.2+build1-0ubuntu0.20.04.1_arm64.deb ; \
        yes | dpkg -i firefox_84.0.2+build1-0ubuntu0.20.04.1_arm64.deb ; \ 
    fi && \
  apt-get clean autoclean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# In the future sudo is fixed see https://github.com/sitespeedio/browsertime/issues/1105
RUN echo "Set disable_coredump false" >> /etc/sudo.conf

# We need a more recent ADB to be able to run Chromedriver 2.39
# COPY files/adb /usr/local/bin/
