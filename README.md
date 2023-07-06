# Firefox, Chrome & Xvfb

Adds specific versions of Chrome, Firefox and Edge to the VisualMetrics dependencies base container for sitespeed.io.

For AMD64 you can choose versions. For ARM64 we use the latest supported version.

We also have xvfb & x11vnc installed.

```
docker buildx build --push --platform linux/arm64,linux/amd64 -t sitespeedio/webbrowsers:chrome-114.0-firefox-115.0-edge-114.0 .
```