#!/bin/bash
set -ex
export VERSION=$(cat debian/changelog | head -n 1 | sed "s/.*(//g" | sed "s/).*//g")
[[ -f .stage ]] && export stage=$(cat .stage) || export stage=0
# Stage 1: Get version and fetch source code
if [[ $stage -lt 1 ]] ; then
    # fetch source
    wget -c https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${VERSION}.tar.xz
    # extrack if directory not exists
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

# Stage 4: Install source code (Like archlinux)
pkgdir=../debian/linux
modulesdir=${pkgdir}/lib/modules/${VERSION}
builddir="$pkgdir/lib/modules/${VERSION}/build"
mkdir -p $pkgdir/boot $pkgdir/usr/src $modulesdir || true
if [[ $stage -lt 4 ]] ; then
    # install bzImage
    install -Dm644 "$(make -s image_name)" "$modulesdir/vmlinuz"
    ln -s ../../boot/vmlinuz-${VERSION}
    # install modules
    make INSTALL_MOD_PATH="$pkgdir" INSTALL_MOD_STRIP=1 modules_install
    rm "$modulesdir"/{source,build} || true
    # install build directories
    install -Dt "$builddir" -m644 Makefile Module.symvers System.map vmlinux || true
    install .config $pkgdir/boot/config-${VERSION}
    install -Dt "$builddir/kernel" -m644 kernel/Makefile
    install -Dt "$builddir/arch/x86" -m644 arch/x86/Makefile
    cp -t "$builddir" -a scripts
    install -Dt "$builddir/tools/objtool" tools/objtool/objtool
    mkdir -p "$builddir"/{fs/xfs,mm}
    # install headers
    cp -t "$builddir" -a include
    cp -t "$builddir/arch/x86" -a arch/x86/include
    install -Dt "$builddir/arch/x86/kernel" -m644 arch/x86/kernel/asm-offsets.s
    install -Dt "$builddir/drivers/md" -m644 drivers/md/*.h
    install -Dt "$builddir/net/mac80211" -m644 net/mac80211/*.h
    install -Dt "$builddir/drivers/media/i2c" -m644 drivers/media/i2c/msp3400-driver.h
    install -Dt "$builddir/drivers/media/usb/dvb-usb" -m644 drivers/media/usb/dvb-usb/*.h
    install -Dt "$builddir/drivers/media/dvb-frontends" -m644 drivers/media/dvb-frontends/*.h
    install -Dt "$builddir/drivers/media/tuners" -m644 drivers/media/tuners/*.h
    find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" \;
    find -L "$builddir" -type l -printf 'Removing %P\n' -delete
    find "$builddir" -type f -name '*.o' -printf 'Removing %P\n' -delete
    ln -s "../../lib/modules/${VERSION}/build" "$pkgdir/usr/src/linux-headers-${VERSION}"
fi
