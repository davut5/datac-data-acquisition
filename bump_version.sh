#!/bin/bash

# set -x				# Turn on trace

ACTION="${1}"

PROJECT=$(osascript -e 'tell application "Xcode" to (path of document 1)')
[[ -d "${PROJECT}" ]] || exit 1
PROJECT="${PROJECT%/*}"

DIR=$(dirname "${PROJECT}")
[[ -d "${DIR}" ]] || exit 1

NAME="${PROJECT##*/}"
NAME="${NAME%%.*}"

let BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${DIR}/${NAME}-Info.plist")
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${DIR}/${NAME}-Info.plist")
let MAJOR=${VERSION%.*}
let MINOR=${VERSION#*.}

case "${ACTION}" in
    view) echo "build: ${BUILD}  major: ${MAJOR}  minor: ${MINOR}"; exit 0 ;;
    build) let BUILD+=1 ;;
    major) let MAJOR+=1; let MINOR=0 ;;
    minor) let MINOR+=1 ;;
    force) BUILD="${2:-${BUILD}}"; MAJOR=${3:-${MAJOR}} MINOR="${4:-${MINOR}}" ;;
    *) echo "*** invalid operation - usage: ${0##*/} [view|build|major|minor|force BUILD MAJOR MINOR]"; exit 1 ;;
esac

VERSION="${MAJOR}.${MINOR}"
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString ${VERSION}" "${DIR}/${NAME}-Info.plist"
/usr/libexec/PlistBuddy -c "Set CFBundleVersion ${BUILD}" "${DIR}/${NAME}-Info.plist"

TAG="${VERSION} (${BUILD})"

DIR="${DIR}/Settings.bundle"

KEY=$(/usr/libexec/PlistBuddy -c "Print :PreferenceSpecifiers:1:Key" "${DIR}/Root.plist")

if [[ "${KEY}" = version ]]; then
    /usr/libexec/PlistBuddy -c "Set :PreferenceSpecifiers:1:DefaultValue \"${TAG}\"" "${DIR}/Root.plist"
fi

KEY=$(/usr/libexec/PlistBuddy -c "Print :PreferenceSpecifiers:1:Key" "${DIR}/Root.inApp.plist")
if [[ "${KEY}" = version ]]; then
    /usr/libexec/PlistBuddy -c "Set :PreferenceSpecifiers:1:DefaultValue \"${TAG}\"" "${DIR}/Root.inApp.plist"
fi

echo "build: ${BUILD}  major: ${MAJOR}  minor: ${MINOR}"
touch "${DIR}"

exit 0
