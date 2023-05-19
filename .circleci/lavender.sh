#!/bin/bash
#
# Script For Building Android arm64 Kernel

# Setup colour for the script
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'

# Deleting out "kernel complied" and zip "anykernel" from an old compilation
echo -e "$green << cleanup >> \n $white"

rm -rf out
rm -rf zip
rm -rf error.log

echo -e "$green << setup dirs >> \n $white"

# With that setup , the script will set dirs and few important thinks

#MY_DIR="${BASH_SOURCE%/*}"
#if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi
 
MY_DIR="$(pwd)"
#IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb

# MIUI = High Dimens
# OSS = Low Dimens

#export CHATID API_BOT TYPE_KERNEL

# Kernel build config
TYPE="LAVENDER"
KERNEL_NAME="SUPER.KERNEL"
KERNEL_NAME_ALIAS="Kernullav-$(date +"%d-%m-%Y").zip"
DEVICE="Redmi Note 7"
DEFCONFIG="lavender-perf_defconfig"
AnyKernel="https://github.com/missgoin/Anykernel3"
AnyKernelbranch="master"
HOSST="Pancali"
USEER="unknown"
ID="03"
MESIN="Git Workflows"

# clang config
#REMOTE="https://gitlab.com"
#TARGET="GhostMaster69-dev"
#REPO="cosmic-clang"
#BRANCH="master"

REMOTE="https://gitlab.com"
TARGET="Panchajanya1999"
REPO="azure-clang"
BRANCH="main"
#git clone --depth=1  https://gitlab.com/Panchajanya1999/azure-clang.git clang

# setup telegram env
export WAKTU=$(date +"%T")
export TGL=$(date +"%d-%m-%Y")

# clang stuff
echo -e "$green << cloning clang >> \n $white"
	git clone --depth=1 -b "$BRANCH" "$REMOTE"/"$TARGET"/"$REPO" "$HOME"/clang
	
        export PATH="$HOME/clang/bin:$PATH"
        #export KBUILD_COMPILER_STRING=$("$HOME"/clang/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' -e 's/^.*clang/clang/')
        export KBUILD_COMPILER_STRING=$("$HOME"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

# Setup build process

build_kernel() {
Start=$(date +"%s")

	make -j$(nproc --all) O=out \
                              ARCH=arm64 \
			      LLVM=1 \
			      LLVM_IAS=1 \
			      AR=llvm-ar \
			      NM=llvm-nm \
			      OBJCOPY=llvm-objcopy \
			      OBJDUMP=llvm-objdump \
			      STRIP=llvm-strip \
			      READELF=llvm-readelf \
			      OBJSIZE=llvm-size \
                              CC=clang \
                              CROSS_COMPILE=aarch64-linux-gnu- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi-  2>&1 | tee error.log

End=$(date +"%s")
Diff=$(($End - $Start))
}

# Let's start
echo -e "$green << doing pre-compilation process >> \n $white"
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64

export KBUILD_BUILD_HOST="$HOSST"
export KBUILD_BUILD_USER="$USEER"
export KBUILD_BUILD_VERSION="$ID"

mkdir -p out

make O=out clean && make O=out mrproper
make ARCH=arm64 O=out "$DEFCONFIG" LLVM=1 LLVM_IAS=1

echo -e "$yellow << compiling the kernel >> \n $white"

build_kernel || error=true

DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)
KOMIT=$(git log --pretty=format:'"%h : %s"' -1)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz-dtb
#export dtbo="$MY_DIR"/out/arch/arm64/boot/dtbo.img
#export dtb="$MY_DIR"/out/arch/arm64/boot/dtb.img

        if [ -f "$IMG" ]; then
                echo -e "$green << selesai dalam $(($Diff / 60)) menit and $(($Diff % 60)) detik >> \n $white"
        else
                echo -e "$red << Gagal dalam membangun kernel!!! , cek kembali kode anda >>$white"
                rm -rf out
                rm -rf testing.log
                rm -rf error.log
                exit 1
        fi

        if [ -f "$IMG" ]; then
                echo -e "$green << cloning AnyKernel from your repo >> \n $white"
                git clone --depth=1 "$AnyKernel" --single-branch -b "$AnyKernelbranch" zip
                echo -e "$yellow << making kernel zip >> \n $white"
                cp -r "$IMG" zip/
                cd zip
                export ZIP="$KERNEL_NAME_ALIAS"
                zip -r9 "$ZIP" * -x .git README.md LICENSE *placeholder
                echo "Zip: $ZIP"
                curl -T $ZIP temp.sh; echo
		
                cd ..
                rm -rf error.log
                rm -rf out
                rm -rf zip
                rm -rf testing.log
				
                exit
        fi





#!/usr/bin/env bash

 #
 # Script For Building Android Kernel
 #

# Bail out if script fails
set -e

##----------------------------------------------------------##
# Basic Information
KERNEL_DIR="$(pwd)"
VERSION=01
MODEL=Xiaomi
DEVICE=lavender
DEFCONFIG=${DEVICE}-perf_defconfig
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
C_BRANCH=$(git branch --show-current)

##----------------------------------------------------------##
## Export Variables and Info
function exports() {
  export ARCH=arm64
  export SUBARCH=arm64
  export LOCALVERSION="-${C_BRANCH}"
  export KBUILD_BUILD_HOST=Pancali
  export KBUILD_BUILD_USER="unknown"
  export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
  export PROCS=$(nproc --all)
  export DISTRO=$(source /etc/os-release && echo "${NAME}")

# Variables
KERVER=$(make kernelversion)
COMMIT_HEAD=$(git log --oneline -1)
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Compiler and Build Information
#TOOLCHAIN=nexus14 # List (clang = nexus14 | aosp | nexus15 | proton )
#LINKER=ld # List ( ld.lld | ld.bfd | ld.gold | ld )
#VERBOSE=0

FINAL_ZIP=SUPER.KERNEL-Lavender-${C_BRANCH}-${TANGGAL}.zip

# CI
        if [ "$CI" ]; then
           if [ "$CIRCLECI" ]; then
                  export CI_BRANCH=${CIRCLE_BRANCH}
           elif [ "$DRONE" ]; then
		  export CI_BRANCH=${DRONE_BRANCH}
           elif [ "$CIRRUS_CI" ]; then
                  export CI_BRANCH=${CIRRUS_BRANCH}
           fi
        fi
}
##----------------------------------------------------------##
## Telegram Bot Integration
##----------------------------------------------------------------##

## Get Dependencies
function clone() {
# Get Toolchain
if [[ $TOOLCHAIN == "azure" ]]; then
       git clone --depth=1  https://gitlab.com/Panchajanya1999/azure-clang clang
elif [[ $TOOLCHAIN == "nexus14" ]]; then
       git clone --depth=1 https://gitlab.com/Project-Nexus/nexus-clang.git -b nexus-14 clang
elif [[ $TOOLCHAIN == "aosp" ]]; then
       git clone --depth=1 https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r433403b.git -b 12.0 clang
elif [[ $TOOLCHAIN == "nexus15" ]]; then
       git clone --depth=1 https://gitlab.com/Project-Nexus/nexus-clang.git -b nexus-15 clang
fi

# Get AnyKernel3
git clone --depth=1 https://github.com/reaPeR1010/AnyKernel3 AK3

# Set PATH
PATH="${KERNEL_DIR}/clang/bin:${PATH}"

# Export KBUILD_COMPILER_STRING
export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
}
##----------------------------------------------------------------##
function compile() {
START=$(date +"%s")

# Push Notification
post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Version : </b><code>$VERSION</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"

# Generate .config
make O=out ARCH=arm64 ${DEFCONFIG}

# Start Compilation
if [[ "$TOOLCHAIN" == "nexus*" || "$TOOLCHAIN" == "proton" ]]; then
     make -kj$(nproc --all) O=out ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- LLVM=1 LLVM_IAS=1 AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip READELF=llvm-readelf OBJSIZE=llvm-size V=$VERBOSE 2>&1 | tee error.log
elif [[ "$TOOLCHAIN" == "aosp" ]]; then
     make -kj$(nproc --all) O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_COMPAT=arm-linux-androideabi- LLVM=1 LLVM_IAS=1 V=$VERBOSE 2>&1 | tee error.log
fi

# Verify Files
	if ! [ -a "$IMAGE" ];
	   then
	       push "error.log" "Build Throws Errors"
	       exit 1
	   else
	       post_msg " Kernel Compilation Finished. Started Zipping "
	fi
}
##----------------------------------------------------------------##
function zipping() {
# Copy Files To AnyKernel3 Zip
cp $IMAGE AK3

# Zipping and Push Kernel
cd AK3 || exit 1
zip -r9 ${FINAL_ZIP} *
MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
cd ..
}
##----------------------------------------------------------##
# Functions
exports
clone
compile
END=$(date +"%s")
DIFF=$(($END - $START))
zipping
##------------------------*****-----------------------------##

