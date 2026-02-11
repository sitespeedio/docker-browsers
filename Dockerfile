FROM sitespeedio/visualmetrics-deps:ffmpeg-7.1.1

ARG TARGETPLATFORM

ENV LC_ALL=C
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

ENV FIREFOX_VERSION=147.*
ENV CHROME_VERSION=145.*
ENV EDGE_VERSION=144.*

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
# Avoid ERROR: invoke-rc.d: unknown initscript, /etc/init.d/systemd-logind not found.

RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d && \
  touch /etc/init.d/systemd-logind

COPY firefox/firefox-no-snap /etc/apt/preferences.d/firefox-no-snap

# Adding sudo for Throttle, lets see if we can find a better place (needed in Ubuntu 17)

# fonts-ipafont-gothic fonts-ipafont-mincho # jp (Japanese) fonts, install seems to solve missing Chinese hk/tw fonts as well.
# ttf-wqy-microhei fonts-wqy-microhei       # kr (Korean) fonts
# fonts-tlwg-loma fonts-tlwg-loma-otf       # th (Thai) fonts
# firefox-locale-hi fonts-gargi		    # Hindi (for now)

RUN fonts='fonts-ipafont-gothic fonts-ipafont-mincho ttf-wqy-microhei fonts-wqy-microhei fonts-tlwg-loma fonts-tlwg-loma-otf fonts-gargi' && \
  buildDeps='bzip2 gnupg wget ca-certificates curl gpg software-properties-common unzip' && \
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
        wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null && \
        echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null && \
        apt-get update && \
        apt-get install -y --no-install-recommends firefox=${FIREFOX_VERSION} && \
        apt-get install -y google-chrome-stable=${CHROME_VERSION} && \
        apt-get install -y microsoft-edge-stable=${EDGE_VERSION} &&  \
        apt-get purge -y --auto-remove $buildDeps; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ] ; \
        then \
          # Get rid of that evil snap version of Firefox
          rm -fR '/usr/bin/firefox' && \
          apt remove --purge snapd -y && \
          apt autoremove -y && \
          rm -rf /var/lib/apt/lists/*  && \
          add-apt-repository -y ppa:xtradeb/apps && \
          apt-get update &&\
          apt-get install -y --no-install-recommends ungoogled-chromium chromium-driver &&\
          apt-get install -y -t 'o=LP-PPA-mozillateam' firefox && \
          apt-get update && \
          ln -s /usr/bin/ungoogled-chromium /usr/local/bin/google-chrome && \
          ln -s /usr/bin/ungoogled-chromium /usr/local/bin/chromium && \
          ln -s /usr/bin/ungoogled-chromiumdriver /usr/local/bin/chromedriver && \
          apt-get purge -y --auto-remove $buildDeps; \
    fi
RUN apt-get clean autoclean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# In the future sudo is fixed see https://github.com/sitespeedio/browsertime/issues/1105
RUN echo "Set disable_coredump false" >> /etc/sudo.conf
