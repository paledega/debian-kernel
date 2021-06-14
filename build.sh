#!/bin/bash
set -ex
export VERSION=$(cat debian/changelog | head -n 1 | sed "s/.*(//g" | sed "s/).*//g")
[[ -f .stage ]] && export stage=$(cat .stage) || export stage=0
# Stage 1: Get version and fetch source code
if [[ $stage -lt 1 ]] ; then
    wget -c https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${VERSION}.tar.xz
    [[ -d linux-${VERSION} ]] || tar -xvf linux-${VERSION}.tar.xz
    echo 1 > .stage
fi

# Stage 2: Generate config
if [[ $stage -lt 2 ]] ; then
    # Config generate
    cp linux-${VERSION}/arch/x86/configs/x86_64_defconfig x86_64_defconfig 
    bash genconfig.sh
    mv config-new linux-${VERSION}/.config
    rm -f x86_64_defconfig config
    echo 2 > .stage
fi

# Enter source
cd linux-${VERSION}

# Stage 3: Build source code
if [[ $stage -lt 3 ]] ; then
    # build source
    yes "" | make bzImage modules -j$(nproc)
    echo 3 > ../.stage
fi

