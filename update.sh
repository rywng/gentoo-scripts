#!/bin/sh

if [ ! $(id -u) -eq 0 ]; then
	echo "Run this program as root"
	exit 1
fi

echo "Syncing repos"
emaint --auto sync
emerge --regen --jobs=`nproc` --quiet
eix-update

echo "GLSA info:"
glsa-check --list

echo "Updating software"
emerge -atvquDN @world &&
	emerge --depclean

if command -v flatpak > /dev/null ; then
	echo "Updating flatpak"
	flatpak update -y
	flatpak uninstall --unused -y --delete-data
fi

echo "Cleaning up old distfiles"
eclean-dist --time-limit=2w
