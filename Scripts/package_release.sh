#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

VERSION="1.0.3"
ZIP_NAME="iPaper-v${VERSION}-macOS.zip"

echo "=== Building Release Bundle ==="
./Scripts/build_app.sh

echo "=== Creating Release Archive ${ZIP_NAME} ==="
cd build
rm -f "${ZIP_NAME}"
zip -r -y "${ZIP_NAME}" "iPaper.app"

SHA256=$(shasum -a 256 "${ZIP_NAME}" | awk '{print $1}')
echo "========================================="
echo "Artifact: build/${ZIP_NAME}"
echo "SHA-256:  ${SHA256}"
echo "Version:  ${VERSION}"
echo "========================================="

cd "$DIR"
mkdir -p release_info
echo "${VERSION}" > release_info/version.txt
echo "${SHA256}" > release_info/sha256.txt
echo "${ZIP_NAME}" > release_info/artifact.txt

