#!/usr/bin/env bash

APP=firefox

# TEMPORARY DIRECTORY
mkdir -p tmp
cd ./tmp || exit 1

# DOWNLOAD APPIMAGETOOL
if ! test -f ./appimagetool; then
	wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool || exit 1
	chmod a+x ./appimagetool
fi

# CREATE FIREFOX BROWSER APPIMAGES

LAUNCHER="[Desktop Entry]
Version=1.0
Name=Firefox
GenericName=Web Browser
GenericName[ca]=Navegador web
GenericName[cs]=Webový prohlížeč
GenericName[es]=Navegador web
GenericName[fa]=مرورگر اینترنتی
GenericName[fi]=WWW-selain
GenericName[fr]=Navigateur Web
GenericName[hu]=Webböngésző
GenericName[it]=Browser Web
GenericName[ja]=ウェブ・ブラウザ
GenericName[ko]=웹 브라우저
GenericName[nb]=Nettleser
GenericName[nl]=Webbrowser
GenericName[nn]=Nettlesar
GenericName[no]=Nettleser
GenericName[pl]=Przeglądarka WWW
GenericName[pt]=Navegador Web
GenericName[pt_BR]=Navegador Web
GenericName[sk]=Internetový prehliadač
GenericName[sv]=Webbläsare
Comment=Browse the Web
Comment[ca]=Navegueu per el web
Comment[cs]=Prohlížení stránek World Wide Webu
Comment[de]=Im Internet surfen
Comment[es]=Navegue por la web
Comment[fa]=صفحات شبکه جهانی اینترنت را مرور نمایید
Comment[fi]=Selaa Internetin WWW-sivuja
Comment[fr]=Navigue sur Internet
Comment[hu]=A világháló böngészése
Comment[it]=Esplora il web
Comment[ja]=ウェブを閲覧します
Comment[ko]=웹을 돌아 다닙니다
Comment[nb]=Surf på nettet
Comment[nl]=Verken het internet
Comment[nn]=Surf på nettet
Comment[no]=Surf på nettet
Comment[pl]=Przeglądanie stron WWW
Comment[pt]=Navegue na Internet
Comment[pt_BR]=Navegue na Internet
Comment[sk]=Prehliadanie internetu
Comment[sv]=Surfa på webben
Exec=$APP %u
Terminal=false
Type=Application
Icon=$APP
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
Categories=Network;WebBrowser;
Keywords=web;browser;internet;"

POLICIES='{
"policies": 
   {
     "DisableAppUpdate": true
    }
}'

_create_firefox_appimage() {
	# Detect the channel
	if [ "$CHANNEL" != stable ]; then
		DOWNLOAD_URL="https://download.mozilla.org/?product=$APP-$CHANNEL-latest&os=linux64"
	else
		DOWNLOAD_URL="https://download.mozilla.org/?product=$APP-latest&os=linux64"
	fi
	# Download with wget or wget2
	if wget --version | head -1 | grep -q ' 1.'; then
		wget -q --no-verbose --show-progress --progress=bar "$DOWNLOAD_URL" --trust-server-names || exit 1
	else
		wget "$DOWNLOAD_URL" --trust-server-names || exit 1
	fi
	# Disable automatic updates
	mkdir -p "$APP".AppDir/distribution
	echo "$POLICIES" > "$APP".AppDir/distribution/policies.json
	# Extract the archive
	[ -e ./*tar.* ] && tar fx ./*tar.* && mv ./firefox/* "$APP".AppDir/ && rm -f ./*tar.* || exit 1
	# Enter the AppDir
	cd "$APP".AppDir || exit 1
	# Add the launcher and patch it depending on the release channel
	echo "$LAUNCHER" > firefox.desktop
	if [ "$CHANNEL" != stable ]; then
		sed -i "s/Name=Firefox/Name=Firefox ${CHANNEL^}/g" firefox.desktop
	fi
	# Add the icon
	cp ./browser/chrome/icons/default/default128.png firefox.png
	cd .. || exit 1

	# Check the version
	VERSION=$(cat ./"$APP".AppDir/application.ini | grep "^Version=" | head -1 | cut -c 9-)

	# Create te AppRun
	cat <<-'HEREDOC' >> ./"$APP".AppDir/AppRun
	#!/bin/sh
	HERE="$(dirname "$(readlink -f "${0}")")"
	export UNION_PRELOAD="${HERE}"
	exec "${HERE}"/firefox "$@"
	HEREDOC
	chmod a+x ./"$APP".AppDir/AppRun

	# Export the AppDir to an AppImage
	ARCH=x86_64 ./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
		-u "gh-releases-zsync|$GITHUB_REPOSITORY_OWNER|Firefox-appimage|continuous-$CHANNEL|*-$CHANNEL-*x86_64.AppImage.zsync" \
		./"$APP".AppDir Firefox-"$CHANNEL"-"$VERSION"-x86_64.AppImage || exit 1
}

CHANNEL="stable"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_firefox_appimage
cd .. || exit 1
mv ./"$CHANNEL"/*.AppImage* ./

CHANNEL="esr"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_firefox_appimage
cd .. || exit 1
mv ./"$CHANNEL"/*.AppImage* ./

CHANNEL="beta"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_firefox_appimage
cd .. || exit 1
mv ./"$CHANNEL"/*.AppImage* ./

CHANNEL="devedition"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_firefox_appimage
cd .. || exit 1
mv ./"$CHANNEL"/*.AppImage* ./

CHANNEL="nightly"
mkdir -p "$CHANNEL" && cp ./appimagetool ./"$CHANNEL"/appimagetool && cd "$CHANNEL" || exit 1
_create_firefox_appimage
cd .. || exit 1
mv ./"$CHANNEL"/*.AppImage* ./

cd ..
mv ./tmp/*.AppImage* ./
