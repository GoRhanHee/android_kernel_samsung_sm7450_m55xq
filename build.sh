#!/bin/bash

# Import KernelSU-Next with SuSFS
(cd kernel_platform/common && curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/dev_susfs/kernel/setup.sh" | bash -s dev_susfs)

# OEM Setting
BUILD_TARGET=m55xq_swa_open
export MODEL=$(echo $BUILD_TARGET | cut -d'_' -f1)
export PROJECT_NAME=${MODEL}
export REGION=$(echo $BUILD_TARGET | cut -d'_' -f2)
export CARRIER=$(echo $BUILD_TARGET | cut -d'_' -f3)
export TARGET_BUILD_VARIANT=user		
		
CHIPSET_NAME=x55

export ANDROID_BUILD_TOP=$(pwd)
export TARGET_PRODUCT=gki
export TARGET_BOARD_PLATFORM=gki

export ANDROID_PRODUCT_OUT=${ANDROID_BUILD_TOP}/out/target/product/${MODEL}
export OUT_DIR=${ANDROID_BUILD_TOP}/out/msm-${CHIPSET_NAME}-${CHIPSET_NAME}-${TARGET_PRODUCT}

export IS_KBUILD=true

# Build Setting
export GKI_KERNEL_BUILD_OPTIONS="
    SKIP_MRPROPER=1 \
    LTO=thin \
    HERMETIC_TOOLCHAIN=0 \
    KMI_SYMBOL_LIST_STRICT_MODE=0 \
    RECOMPILE_KERNEL=1 \
    ABI_DEFINITION= \
    BUILD_BOOT_IMG=1 \
    SKIP_VENDOR_BOOT=1 \
    MKBOOTIMG_PATH=${ANDROID_BUILD_TOP}/kernel_platform/tools/mkbootimg/mkbootimg.py \
    KERNEL_BINARY=Image \
    BOOT_IMAGE_HEADER_VERSION=4 \
    AVB_SIGN_BOOT_IMG=1 \
    AVB_BOOT_PARTITION_SIZE=100663296 \
    AVB_BOOT_KEY=${ANDROID_BUILD_TOP}/kernel_platform/tools/mkbootimg/tests/data/testkey_rsa2048.pem \
    AVB_BOOT_ALGORITHM=SHA256_RSA2048 \
    AVB_BOOT_PARTITION_NAME=boot  
"

# MKBOOTIMG Setting
export MKBOOTIMG_EXTRA_ARGS="
    --os_version 12.0.0 \
    --os_patch_level 2025-12-00 \
    --pagesize 4096 \
"

# Import Samsung toolchain
TOOLCHAIN_URL="https://github.com/GoRhanHee/samsung_sm7450_toolchain/releases/download/toolchain/toolchain.tar.xz"
TOOLCHAIN_FILE=$(basename "$TOOLCHAIN_URL")
if [ ! -f "$TOOLCHAIN_FILE" ]; then
    wget -q --show-progress --progress=dot:giga -O "$TOOLCHAIN_FILE" "$TOOLCHAIN_URL"
fi
tar -xf "$TOOLCHAIN_FILE" -C kernel_platform && rm "$TOOLCHAIN_FILE"

# Cooking Kernel
( env ${GKI_KERNEL_BUILD_OPTIONS} ${ANDROID_BUILD_TOP}/kernel_platform/build/android/prepare_vendor.sh ${CHIPSET_NAME} ${TARGET_PRODUCT} gki | tee -a ../build.log )
