#!/bin/bash

FFMPEG_LATEST=$(git ls-remote -t https://github.com/FFmpeg/FFmpeg | cut -f 2 | grep '^refs/tags/n' | grep -v -- -dev | grep -v {} | cut -d '/' -f 3 | sed 's/^n//' | sort -Vr | head -n 1)
echo ffmpeg $FFMPEG_LATEST

[ "$FFMPEG_LATEST" = "" ] && exit 1

sed -i.bak "s/FFMPEG_VERSION=.*/FFMPEG_VERSION=$FFMPEG_LATEST/g" Dockerfile
rm -f Dockerfile.bak
if ! git diff --quiet Dockerfile ; then
  git add Dockerfile
  git commit -m "Update ffmpeg to $FFMPEG_LATEST"
  git tag $FFMPEG_LATEST
  git push --tags origin master
fi
