#!/bin/bash
set  -e
dir=$(dirname  "$0")
cd  "$dir"


# image & versions
image="qubes-pass"
version="0.0.22"
release="1"
version1="$version-$release"


# cache settings
cache_dir="./build/cache"
cache_from="--cache-from=type=local,src=$cache_dir"
cache_to="--cache-to=type=local,mode=max,dest=$cache_dir"
cache="$cache_from $cache_to"
mkdir  -p  $cache_dir


# docker settings
export DOCKER_BUILDKIT=1
export DOCKER_CLI_EXPERIMENTAL=enabled
export BUILDX_NO_DEFAULT_LOAD=0


# build
docker  buildx  build           \
  --pull                        \
  --load                        \
  $cache                        \
  --build-arg VERSION=$version  \
  --build-arg RELEASE=$release  \
  --target=out                  \
  --tag $image:$version1        \
  --file ./Dockerfile           \
  .                             \
;
echo  "### build: $image:$version1"


mkdir  -p  ./build/$version1/


# extract deb files
debs=( "client" "service" )
for deb in "${debs[@]}" ; do
  file="./build/$version1/qubes-pass-${deb}_${version1}.deb"
  docker  run  --rm  $platform  --entrypoint cat  $image:$version1  /qubes-pass-${deb}.deb  >$file
  echo  "### extracted: $file"
done


# extract rpm files
rpms=( "client" "service" "dom0" )
for rpm in "${rpms[@]}" ; do
  file="./build/$version1/qubes-pass-${rpm}_${version1}.rpm"
  docker  run  --rm  $platform  --entrypoint cat  $image:$version1  /qubes-pass-${deb}.rpm  >$file
  echo  "### extracted: $file"
done
