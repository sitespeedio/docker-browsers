# Firefox, Chrome & Xvfb

Adds specific versions of Chrome, Firefox and Edge to the VisualMetrics dependencies base container for sitespeed.io.

For AMDD64 you can choose versions. For amm64 we only support Firefox at the moment.

We also have xvfb & x11vnc installed.

```
docker buildx build --push --platform linux/arm64,linux/amd64 -t sitespeedio/webbrowsers:chrome-98.0-firefox-94.0-edge-97.0
```