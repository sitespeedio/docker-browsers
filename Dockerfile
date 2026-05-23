FROM sitespeedio/visualmetrics-deps:ffmpeg-7.1.1-c

ARG TARGETPLATFORM
ARG FIREFOX_VERSION=150.*
ARG CHROME_VERSION=148.*
ARG EDGE_VERSION=147.*

ENV LC_ALL=C
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
# Avoid ERROR: invoke-rc.d: unknown initscript, /etc/init.d/systemd-logind not found.

RUN printf '#!/bin/sh\nexit 0\n' > /usr/sbin/policy-rc.d && \
  touch /etc/init.d/systemd-logind

COPY firefox/firefox-no-snap /etc/apt/preferences.d/firefox-no-snap

# Adding sudo for Throttle, lets see if we can find a better place (needed in Ubuntu 17)

# fonts-ipafont-gothic fonts-ipafont-mincho # jp (Japanese) fonts, install seems to solve missing Chinese hk/tw fonts as well.
# ttf-wqy-microhei fonts-wqy-microhei       # kr (Korean) fonts
# fonts-tlwg-loma fonts-tlwg-loma-otf       # th (Thai) fonts
# firefox-locale-hi fonts-gargi		    # Hindi (for now)

RUN fonts='fonts-ipafont-gothic fonts-ipafont-mincho ttf-wqy-microhei fonts-wqy-microhei fonts-tlwg-loma fonts-tlwg-loma-otf fonts-gargi' && \
  buildDeps='bzip2 gnupg gpg software-properties-common unzip' && \
  xvfbDeps='xvfb libgl1-mesa-dri xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic dbus-x11' && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    $buildDeps \
    android-tools-adb \
    ca-certificates \
    wget \
    x11vnc \
    sudo \
    iproute2 \
    $fonts \
    $xvfbDeps && \
  install -m 0755 -d /etc/apt/keyrings && \
  if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
      wget -q -O- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/keyrings/google-chrome.gpg && \
      echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
      wget -q -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/microsoft.gpg && \
      echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list && \
      wget -q -O- https://packages.mozilla.org/apt/repo-signing-key.gpg > /etc/apt/keyrings/packages.mozilla.org.asc && \
      echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list && \
      apt-get update && \
      apt-get install -y --no-install-recommends firefox=${FIREFOX_VERSION} && \
      apt-get install -y \
        google-chrome-stable=${CHROME_VERSION} \
        microsoft-edge-stable=${EDGE_VERSION}; \
  elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
      # Get rid of that evil snap version of Firefox
      rm -fR '/usr/bin/firefox' && \
      apt-get remove --purge -y snapd && \
      apt-get autoremove -y && \
      rm -rf /var/lib/apt/lists/* && \
      add-apt-repository -y ppa:xtradeb/apps && \
      apt-get update && \
      apt-get install -y --no-install-recommends ungoogled-chromium chromium-driver && \
      apt-get install -y -t 'o=LP-PPA-mozillateam' firefox && \
      ln -s /usr/bin/ungoogled-chromium /usr/local/bin/google-chrome && \
      ln -s /usr/bin/ungoogled-chromium /usr/local/bin/chromium && \
      ln -s /usr/bin/ungoogled-chromiumdriver /usr/local/bin/chromedriver; \
  else \
      echo "Unsupported TARGETPLATFORM: $TARGETPLATFORM" >&2 && exit 1; \
  fi && \
  { command -v google-chrome >/dev/null 2>&1 || command -v google-chrome-stable >/dev/null 2>&1; } || \
    { echo "ERROR: chrome binary not found on PATH after install" >&2; exit 1; } && \
  apt-get purge -y --auto-remove $buildDeps && \
  apt-get clean autoclean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# In the future sudo is fixed see https://github.com/sitespeedio/browsertime/issues/1105
RUN echo "Set disable_coredump false" >> /etc/sudo.conf
