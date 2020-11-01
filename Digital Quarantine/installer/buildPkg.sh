# Run this script in the directory containing the .app file

app_name="Digital Quarantine.app"
installer_name="DigitalQuarantineInstaller.pkg"
bundle_dir="to_bundle"
scripts_dir="Scripts"

if [ -e $installer_name ]
then
    rm -rf $installer_name
fi

if [ -d $bundle_dir ]
then
    rm -rf $bundle_dir
fi

mkdir $bundle_dir
mv "$app_name" $bundle_dir

chmod 755 $scripts_dir/postinstall

pkgbuild --root $bundle_dir --scripts $scripts_dir --identifier com.unnecessary-labs.mac.Digital-Quarantine --install-location /Applications/ DQ.pkg
productbuild --distribution distribution.xml --resources ./resources/ $installer_name

rm -rf DQ.pkg