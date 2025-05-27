#!/bin/bash
set -xe

# --- Configuration ---
APP_NAME="Digital Quarantine"
APP_BUNDLE_ID="com.bharath.Digital-Quarantine"
INSTALL_LOCATION="/Applications"
OUTPUT_PKG_NAME="DigitalQuarantineInstaller.pkg"
# --- END Configuration ---


# This assumes a standard Xcode build setup
# Get the build products path for the specific configuration (Release).
# CONFIGURATION_BUILD_DIR points directly to the output directory for a given config.
# We use 'head -n 1' to take only the first match, which typically corresponds to the main app target.
BUILD_PRODUCTS_DIR=$(xcodebuild -project "${APP_NAME}.xcodeproj" \
                     -scheme "${APP_NAME}" \
                     -configuration Release \
                     -showBuildSettings | \
                     grep -w "CONFIGURATION_BUILD_DIR" | \
                     awk '{print $3}' | head -n 1)

APP_BUNDLE_PATH="${BUILD_PRODUCTS_DIR}/${APP_NAME}.app"

echo "App Bundle Path: ${APP_BUNDLE_PATH}"
echo "Output Package: ${OUTPUT_PKG_NAME}"

# Check if the app bundle exists
if [ ! -d "${APP_BUNDLE_PATH}" ]; then
    echo "Error: App bundle not found at ${APP_BUNDLE_PATH}."
    echo "Please ensure the app is built for 'Release' configuration."
    echo "You might need to run 'xcodebuild -project \"${APP_NAME}.xcodeproj\" -scheme \"${APP_NAME}\" -configuration Release build' first."
    exit 1
fi

# Create the installer package using pkgbuild
# This command creates a component package containing your app.
pkgbuild \
    --component "${APP_BUNDLE_PATH}" \
    --install-location "${INSTALL_LOCATION}" \
    "${OUTPUT_PKG_NAME}"

if [ $? -eq 0 ]; then
    echo "Successfully created installer: ${OUTPUT_PKG_NAME}"
    echo "Remember: This app is UNsigned and UNnotarized. Users will see Gatekeeper warnings."
    echo "The 'Start at Login' feature is managed by the app itself and relies on user permissions."
else
    echo "Error: Failed to create installer package."
    exit 1
fi