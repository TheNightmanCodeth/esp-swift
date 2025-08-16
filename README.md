# Docker images for embedded-swift development on ESP32c6 based boards

This repository contains misc dockerfiles I use to build the images for
[greenhouse-monitor](TheNightmanCodeth/greenhouse-monitor)

## Multi-stage

The [root Dockerfile](Dockerfile) is a multi-stage image which effectively
combines the [swift-latest](swift-latest), [esp-idf](esp-idf), and
[esp-matter](esp-matter) images into a single image.

## Goals

The core goal of this repo is to provide images which make the process of
getting started with [swift-embedded](swiftlang/swift-embedded-examples) and
[swift-matter](swiftlang/swift-matter) easier. Unfortunately to realize this
goal, as it turns out, was not quite as easy as I initially thought. See
challenges below for more info on that.

[ ] Provide `swift-latest` image as a starting point for other images [ ]
Provide `swift-esp-idf` image for [esp-idf](espressif/esp-idf) swift development
[ ] Provide `swift-matter` image for [esp-matter](espressif/esp-matter) swift
development (all-encompassing) [ ] All images are compatible with
[container](apple/container) on macOS 26 (15 support sounds spotty but should
come along)

## Challenges

Along the way I discovered a few challenges:

- The image is massive (~11g)
- [contianer](apple/container) is broken right now
- GitHub Actions runners disk space caps out far below my needs

The first "challenge" is really just the third one in disguise. The `esp-matter`
and `esp-idf` repos are huge so they take up about as much disk space on a
non-container environment. The problem really is that GitHub doesn't give me
enough disk space to run scheduled builds. To solve this I've set up a
self-hosted runner on an old mac mini which introduces reliability concerns in
the event I forget this project exists.

Effectively this just means that in order to actually run the CI/CD pipeline
yourself requires you to do the same. Luckily the process is quite easy.

## Using the Images

Obviously there are multiple ways to use the images. The most obvious is likely
just to spin up a container with your codebase mounted inside and simply shell
in & `idf.py build`.

One could also chop up a Dockerfile to run i.e., tests in CI/CD pielines

```Dockerfile
FROM ghcr.io/TheNightmanCodeth/esp-swift:swift-matter

COPY source /code
WORKDIR /code
RUN idf.py build # etc.
```

It's just some docker images after all, do whatever you want with them.
