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
  export PROCS=$(nproc --all)
  export DISTRO=$(source /etc/os-release && echo "${NAME}")

# Variables
KERVER=$(make kernelversion)
COMMIT_HEAD=$(git log --oneline -1)
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Compiler and Build Information
TOOLCHAIN=azure # List (clang = nexus14 | aosp | nexus15 | proton )
#LINKER=ld # List ( ld.lld | ld.bfd | ld.gold | ld )
VERBOSE=0

FINAL_ZIP=SUPER.KERNEL-Lavender-${C_BRANCH}-${TANGGAL}.zip
FINAL_ZIP_ALIAS=Kernullav-${TANGGAL}.zip

# CI

}

##----------------------------------------------------------##
## Telegram Bot Integration
##----------------------------------------------------------##

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
#post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Version : </b><code>$VERSION</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"

# Generate .config
make O=out ARCH=arm64 ${DEFCONFIG}

# Start Compilation
if [[ "$TOOLCHAIN" == "azure" || "$TOOLCHAIN" == "proton" ]]; then
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

echo "Zip: $FINAL_ZIP"
curl -T $FINAL_ZIP temp.sh; echo

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

