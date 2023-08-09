#!/bin/bash

set -ex

function version_build_id {
    version=$1
    suffix=${version#*-}
    if [ "$suffix" = "$version" ]; then
	# Dummy BuildID used when official BuildID is unknown.
        echo "20200101.1"
    else
	revision=${suffix##*.}
	suffix=${suffix%.*}
	short_date=${suffix##*.}
	yy=$((${short_date} / 1000))
	mm=$(((${short_date} - 1000 * ${yy}) / 50))
	dd=$((${short_date} - 1000 * ${yy} - 50 * ${mm}))
	printf "20%02d%02d%02d.%s\n" $yy $mm $dd $revision
    fi
}

BASEDIR=/src/artifacts
PACKAGESDIR=${BASEDIR}/local-packages
DOWNLOADDIR=${BASEDIR}/local-downloads
OUTPUTDIR=${BASEDIR}/output

rm -rf ${PACKAGESDIR}
mkdir -p ${PACKAGESDIR}
rm -rf ${DOWNLOADDIR}
mkdir -p ${DOWNLOADDIR}
rm -rf ${OUTPUTDIR}
mkdir -p ${OUTPUTDIR}

cd /src

pushd runtime
RUNTIME_VERSION=8.0.0-preview.5.23280.8
ROOTFS_DIR=/rootfs ./build.sh --ci -c Release --restore --build \
 -arch x64 -cross -clang --ninja \
 /p:OfficialBuildId=$(version_build_id ${RUNTIME_VERSION}) \
 --nodereuse false --warnAsError false
mkdir -p ${DOWNLOADDIR}/Runtime/${RUNTIME_VERSION}
cp artifacts/packages/Release/Shipping/dotnet-runtime-*-linux-x64.tar.gz ${DOWNLOADDIR}/Runtime/${RUNTIME_VERSION}
cp artifacts/packages/Release/Shipping/dotnet-runtime-*-linux-x64.tar.gz ${OUTPUTDIR}
cp artifacts/packages/Release/Shipping/*.nupkg ${PACKAGESDIR}
cp artifacts/packages/Release/Shipping/*.tar.gz ${OUTPUTDIR}
popd


# build.sh  --ci --configuration Release --restore --build --pack --publish \
#  -bl /p:ArcadeBuildFromSource=true /p:CopyWipIntoInnerSourceBuildRepo=true \
#  /p:DotNetBuildOffline=true /p:CopySrcInsteadOfClone=true \
#  /p:AdditionalSourceBuiltNupkgCacheDir="/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/artifacts/obj/x64/Release/blob-feed/packages/" \
#  /p:ReferencePackageNupkgCacheDir="/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/prereqs/packages/reference/" \
#  /p:PreviouslySourceBuiltNupkgCacheDir="/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/prereqs/packages/previously-source-built/" \
#  /p:SourceBuildUseMonoRuntime= --v minimal --nodereuse false --warnAsError false \
#  /p:DisableNerdbankVersioning=true /p:DotNetCoreSdkDir=/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/.dotnet/


SDK_VERSION=8.0.100-preview.5.23303.1
pushd sdk
git config --global --add safe.directory /src/sdk
./build.sh --pack --ci -c Release /p:Architecture=x64 /p:OfficialBuildId=$(version_build_id ${SDK_VERSION})
mkdir -p ${DOWNLOADDIR}/Sdk/${SDK_VERSION}
cp artifacts/packages/Release/NonShipping/dotnet-toolset-internal-*.zip ${DOWNLOADDIR}/Sdk/${SDK_VERSION}
cp artifacts/packages/Release/Shipping/*.nupkg ${PACKAGESDIR}
popd

# build.sh  --ci --configuration Release --restore --build --pack --publish -bl \
#  /p:ArcadeBuildFromSource=true /p:CopyWipIntoInnerSourceBuildRepo=true \
#  /p:DotNetBuildOffline=true /p:CopySrcInsteadOfClone=true \
#  /p:AdditionalSourceBuiltNupkgCacheDir="/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/artifacts/obj/x64/Release/blob-feed/packages/" \
#  /p:ReferencePackageNupkgCacheDir="/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/prereqs/packages/reference/" \
#  /p:PreviouslySourceBuiltNupkgCacheDir="/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/prereqs/packages/previously-source-built/" \
#  /p:SourceBuildUseMonoRuntime= --runtime-id ubuntu.20.04-x64 /p:NETCoreAppMaximumVersion=99.9 
#  /p:OSName=ubuntu.20.04 /p:PortableOSName=linux /p:Rid=ubuntu.20.04-x64 /p:DOTNET_INSTALL_DIR=/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/.dotnet/ \
#  /p:AspNetCoreInstallerRid=ubuntu.20.04-x64 /p:CoreSetupRid=ubuntu.20.04-x64 \
#  /p:PublicBaseURL=file:///home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/artifacts/obj/x64/Release/blob-feed/assets/ \
#  /p:UsePortableLinuxSharedFramework=false

ASPNETCORE_VERSION=8.0.0-preview.5.23302.2
pushd aspnetcore
mkdir -p /root/.config/yarn
touch /root/.config/yarn/config
chmod ugo+rwx /root/.config/yarn
chmod ugo+rwx /root/.config/yarn/config
chmod -R 777 /root/ # this is terrible, but its the only thing that works

git config --global --add safe.directory /src/aspnetcore
chmod 666 /src/aspnetcore/src/SignalR/clients/ts/signalr/package.json
chmod 666 /src/aspnetcore/src/SignalR/clients/ts/signalr-protocol-msgpack/package.json
chmod 666 /src/aspnetcore/src/JSInterop/Microsoft.JSInterop.JS/src/package.json

./eng/build.sh --pack --ci -c Release -arch x64 /p:OfficialBuildId=$(version_build_id ${ASPNETCORE_VERSION}) # /p:DotNetAssetRootUrl=file://${DOWNLOADDIR}/
cp artifacts/packages/Release/Shipping/*.nupkg ${PACKAGESDIR}
mkdir -p ${DOWNLOADDIR}/aspnetcore/Runtime/${ASPNETCORE_VERSION}
cp artifacts/installers/Release/aspnetcore-runtime-internal-*-linux-x64.tar.gz ${DOWNLOADDIR}/aspnetcore/Runtime/${ASPNETCORE_VERSION}
cp artifacts/installers/Release/aspnetcore_base_runtime.version ${DOWNLOADDIR}/aspnetcore/Runtime/${ASPNETCORE_VERSION}
popd

# build.sh --ci --configuration Release --restore --build --pack  
#  -bl /p:ArcadeBuildFromSource=true /p:CopyWipIntoInnerSourceBuildRepo=true 
#  /p:DotNetBuildOffline=true /p:CopySrcInsteadOfClone=true 
#  /p:DotNetPackageVersionPropsPath="/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/artifacts/obj/x64/Release/PackageVersions.aspnetcore.props" 
#  /p:AdditionalSourceBuiltNupkgCacheDir="/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/artifacts/obj/x64/Release/blob-feed/packages/" 
#  /p:ReferencePackageNupkgCacheDir="/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/prereqs/packages/reference/" 
#  /p:PreviouslySourceBuiltNupkgCacheDir="/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/prereqs/packages/previously-source-built/" 
#  /p:SourceBuildUseMonoRuntime= --arch x64 --no-build-repo-tasks --no-build-nodejs 
#  /p:PublishCompressedFilesPathPrefix=/home/agupta5/code/bb-dotnet/net8/dotnet-dotnet/artifacts/obj/x64/Release/blobs/aspnetcore/Runtime/ 
#  /p:PortableBuild=false /p:TargetRuntimeIdentifier=ubuntu.20.04-x64 /p:MicrosoftNetFrameworkReferenceAssembliesVersion=1.0.0


# pushd vstest
# git config --global --add safe.directory /src/vstest
# ./build.sh -c Release
# cp artifacts/Release/packages/*.nupkg ${DOWNLOADDIR}
# popd


# INSTALLER_VERSION=8.0.100-preview.5.23303.2
# pushd installer
# git config --global --add safe.directory /src/installer
# rm -rf artifacts
# # Setting HostRid to linux- instead of ubuntu- avoids requiring Debian installer packages
# ./build.sh --ci -c Release -a x64 /p:OfficialBuildId=$(version_build_id ${INSTALLER_VERSION}) /p:HostRid=linux-x64 /p:PublicBaseURL=file://${DOWNLOADDIR}/
# cp artifacts/packages/Release/Shipping/dotnet-sdk-*-linux-x64.tar.gz ${OUTPUTDIR}
# popd