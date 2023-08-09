#!/bin/bash

set -ex

docker build -t dotnet8centos7builder:squashed -f Dockerfile.centos7 .

rm -rf dotnet8centos7builder
mkdir dotnet8centos7builder
pushd dotnet8centos7builder
docker save dotnet8centos7builder:squashed -o dotnet8centos7builder_squashed.tar
mkdir docker_image_tar
tar -xf dotnet8centos7builder_squashed.tar -C docker_image_tar

pushd docker_image_tar

layer_folder_pre=$(ls -d */ | head -n 1)
layer_folder=${layer_folder_pre::-1}

pushd $layer_folder
mkdir ../../rootfs
tar -xf layer.tar -C ../../rootfs
rm -rf layer_folder
popd # $layer_folder
popd # docker_image_tar
rm -rf docker_image_tar
rm -rf dotnet8centos7builder_squashed.tar

ls -lrt 
mkdir src
pushd src

git clone --depth 1 --branch v8.0.0-preview.5.23280.8 https://github.com/dotnet/runtime.git
pushd runtime
git apply ../../../patches/runtime-patches/runtime-genmoduleindex.patch
popd # runtime

git clone --depth 1 --branch v8.0.100-preview.5.23303.1 https://github.com/dotnet/sdk
pushd sdk
git submodule init
git submodule update
sed -e "s#@@PACKAGESDIR@@#/src/artifacts/local-packages#" <../../../patches/sdk-patches/diff-sdk-hack-localrepo.in >../../../patches/sdk-patches/diff-sdk-hack-localrepo.patch
git apply ../../../patches/sdk-patches/diff-sdk-hack-localrepo.patch
popd # sdk

git clone --depth 1 --branch v8.0.0-preview.5.23302.2 https://github.com/dotnet/aspnetcore.git
pushd aspnetcore
git submodule init
git submodule update
popd # aspnetcore

git clone --depth 1 --branch v17.7.0 https://github.com/microsoft/vstest.git
pushd vstest
git submodule update --init --recursive --progress
popd # vstest

git clone --depth 1 --branch v8.0.100-preview.5.23303.2 https://github.com/dotnet/installer.git
pushd installer
git submodule init
git submodule update
popd # installer

popd # src
popd # dotnet8centos7builder
docker build -t dotnet8centos8builder:latest -f Dockerfile.centos8 .
docker run -v ./dotnet8centos7builder/rootfs:/rootfs:rw -v ./dotnet8centos7builder/src:/src:rw dotnet8centos8builder:latest


