wget -c https://salsa.debian.org/kernel-team/linux/-/raw/master/debian/config/config
cat config > config-new
# defconfig apply
cat x86_64_defconfig | while read line ; do
  if [[ ${line:0:1} != "#" ]] ; then
    name=${line%=*}
    sed -i "s/.*${name}=.*/${line}/g" config-new
    sed -i "s/.*${name} is not set/$line/g" config-new
  fi
done
# remove key
sed -i "/CONFIG_SYSTEM_TRUSTED_KEYS/d" config-new
for config in CONFIG_OVERLAY_FS CONFIG_SQUASHFS CONFIG_HFSPLUS_FS CONFIG_SCSI CONFIG_KERNEL_MODULES ; do
  sed -i "s/.*${config}=.*/${config}=y/g" config-new
  sed -i "s/.*${config} is not set/${config}=y/g" config-new ;
done

for config in CONFIG_HIBERNATION CONFIG_SECURITY_SELINUX ; do
  sed -i "s/^${name}=.*/# ${config} in not set/g" config-new
done

