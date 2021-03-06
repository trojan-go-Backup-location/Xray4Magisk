#!/sbin/sh
#####################
# xray Customization
#####################
SKIPUNZIP=1

# prepare xray execute environment
ui_print "- Prepare xray execute environment."
mkdir -p /data/xray
mkdir -p /data/xray/run
mkdir -p /data/xray/bin
mkdir -p /data/xray/confs
mkdir -p $MODPATH/scripts

download_xray_zip="/data/xray/run/xray-core.zip"
custom="/sdcard/Download/Xray-core.zip"

if [ -f "${custom}" ]; then
  cp "${custom}" "${download_xray_zip}"
  ui_print "Info: Custom Xray-core found, starting installer"
  latest_xray_version=custom
else
  case "${ARCH}" in
    arm)
      version="Xray-linux-arm32-v7a.zip"
      ;;
    arm64)
      version="Xray-android-arm64-v8a.zip"
      ;;
    x86)
      version="Xray-linux-32.zip"
      ;;
    x64)
      version="Xray-linux-64.zip"
      ;;
  esac
  if [ -f /sdcard/Download/"${version}" ]; then
    cp /sdcard/Download/"${version}" "${download_xray_zip}"
    ui_print "Info: Xray-core already downloaded, starting installer"
    latest_xray_version=custom
  else
    # download latest xray core from official link
    ui_print "- Connect official xray download link."
    if [ $BOOTMODE ! = true ] ; then
      abort "Error: Please install in Magisk Manager"
    fi
    official_xray_link="https://github.com/XTLS/Xray-core/releases"
    latest_xray_version=`curl -k -s https://api.github.com/repos/XTLS/Xray-core/releases | grep -m 1 "tag_name" | grep -o "v[0-9.]*"`
    if [ "${latest_xray_version}" = "" ] ; then
      ui_print "Error: Connect official xray download link failed." 
      ui_print "Tips: You can download xray core manually,"
      ui_print "      and put it in /sdcard/Download"
      abort
    fi
    ui_print "- Download latest xray core ${latest_xray_version}-${ARCH}"
    curl "${official_xray_link}/download/${latest_xray_version}/${version}" -k -L -o "${download_xray_zip}" >&2
    if [ "$?" != "0" ] ; then
      ui_print "Error: Download xray core failed."
      ui_print "Tips: You can download xray core manually,"
      ui_print "      and put it in /sdcard/Download"
      abort
    fi
  fi
fi

# install xray execute file
ui_print "- Install xray core $ARCH execute files"
unzip -j -o "${download_xray_zip}" "geoip.dat" -d /data/xray >&2
unzip -j -o "${download_xray_zip}" "geosite.dat" -d /data/xray >&2
unzip -j -o "${download_xray_zip}" "xray" -d /data/xray/bin >&2
unzip -j -o "${ZIPFILE}" 'xray/scripts/*' -d $MODPATH/scripts >&2
unzip -j -o "${ZIPFILE}" 'service.sh' -d $MODPATH >&2
unzip -j -o "${ZIPFILE}" 'uninstall.sh' -d $MODPATH >&2
rm "${download_xray_zip}"
# copy xray data and config
ui_print "- Copy xray config and data files"
[ -f /data/xray/confs/proxy.json ] || \
unzip -j -o "${ZIPFILE}" "xray/etc/confs/*" -d /data/xray/confs >&2
[ -f /data/xray/appid.list] || \
echo ALL > /data/xray/appid.list
# generate module.prop
ui_print "- Generate module.prop"
rm -rf $MODPATH/module.prop
touch $MODPATH/module.prop
echo "id=xray" > $MODPATH/module.prop
echo "name=Xray4Magisk" >> $MODPATH/module.prop
echo -n "version=Module v1.2.3, Core " >> $MODPATH/module.prop
echo ${latest_xray_version} >> $MODPATH/module.prop
echo "versionCode=20210201" >> $MODPATH/module.prop
echo "author=CerteKim" >> $MODPATH/module.prop
echo "description=xray core with service scripts for Android" >> $MODPATH/module.prop

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm  $MODPATH/service.sh    0  0  0755
set_perm  $MODPATH/uninstall.sh    0  0  0755
set_perm  $MODPATH/scripts/start.sh    0  0  0755
set_perm  $MODPATH/scripts/xray.inotify    0  0  0755
set_perm  $MODPATH/scripts/xray.service    0  0  0755
set_perm  $MODPATH/scripts/xray.tproxy     0  0  0755
set_perm  /data/xray                0  0  0755
