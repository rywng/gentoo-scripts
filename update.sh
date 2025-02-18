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
echo

glsa-check --list

echo
echo "Updating software"
sleep 3s

emerge -atvquDN @world &&
	emerge --depclean

echo "Updating flatpak"
flatpak update -y
flatpak uninstall --unused -y --delete-data

echo "Cleaning up old distfiles"
eclean-dist --time-limit=2w
