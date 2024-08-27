FROM sitespeedio/visualmetrics-deps:ffmpeg-5.1.1-j

ARG TARGETPLATFORM

ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ENV FIREFOX_VERSION 129.0
ENV CHROME_VERSION 128.*
ENV EDGE_VERSION 127.*

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
  buildDeps='bzip2 gnupg wget ca-certificates curl gpg software-properties-common' && \
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
      --no-install-recommends

RUN if [ "$TARGETPLATFORM" = "linux/amd64" ] ; \
      then \
        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
        echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
        curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
        install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/  && \
        sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'  && \
        rm microsoft.gpg  && \
        apt-get update && \
        wget https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/en-US/firefox-${FIREFOX_VERSION}.tar.bz2 && \
        tar -xjf firefox-${FIREFOX_VERSION}.tar.bz2 && \
        rm firefox-${FIREFOX_VERSION}.tar.bz2 && \
        mv firefox /opt/ && \
        ln -s /opt/firefox/firefox /usr/local/bin/firefox && \
        # Needed for when we install FF this way
        apt-get install -y libdbus-glib-1-2 && \
        apt-get install -y google-chrome-stable=${CHROME_VERSION} && \
        apt-get install -y microsoft-edge-stable=${EDGE_VERSION} &&  \
        apt-get purge -y --auto-remove $buildDeps; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ] ; \
        then \
          # Get rid of that evil snap version of Firefox
          rm -fR '/usr/bin/firefox' && \
          apt remove --purge snapd -y && \
          apt autoremove -y && \
          apt-get remove --purge libsnapd-qt1 -y && \
          add-apt-repository ppa:mozillateam/ppa -y && \
          apt-get update && \
          apt-get install -y -t 'o=LP-PPA-mozillateam' firefox && \
          add-apt-repository ppa:saiarcot895/chromium-beta && \
          apt-get update && \
          apt-get install -y chromium-browser chromium-chromedriver && \
          ln -s /usr/lib/chromium-browser/chromedriver /usr/local/bin/chromedriver && \
          apt-get purge -y --auto-remove $buildDeps; \
    fi
RUN apt-get clean autoclean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# In the future sudo is fixed see https://github.com/sitespeedio/browsertime/issues/1105
RUN echo "Set disable_coredump false" >> /etc/sudo.conf
