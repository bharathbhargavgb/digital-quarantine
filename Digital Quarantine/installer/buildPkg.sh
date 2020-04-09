# Run this script in the directory containing the .app file

mkdir to_bundle
mv Digital\ Quarantine.app to_bundle

pkgbuild --root to_bundle --identifier com.unnecessary-labs.mac.Digital-Quarantine --install-location /Applications/ DQ.pkg
productbuild --distribution distribution.xml --resources ./resources/ DigitalQuarantineInstaller.pkg

rm -rf DQ.pkg