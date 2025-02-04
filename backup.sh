#!/bin/sh

SNAPSHOT_DIR=/root/snapshots
HOME_SNAPSHOT_DIR=`realpath $SNAPSHOT_DIR/home* | sort | tail -n1`
ROOT_SNAPSHOT_DIR=`realpath $SNAPSHOT_DIR/ROOT* | sort | tail -n1`

# BORG_REPO and BORG_PASSPHRASE should be set in another file not in git
. `dirname $0`/.borg.env

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$(date)" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

if [ -d $HOME_SNAPSHOT_DIR ];then
	borg create \
		::'home-{now}' \
		$HOME_SNAPSHOT_DIR/./*/Documents/ \
		--exclude '*/games/*' \
		--exclude '*/package/*' \
		--exclude '*/target/*' \
		--exclude '*cache*' \
		--show-rc \
		--stats \
		--progress \
		-C zstd,8
fi

borg create \
	::'root-{now}' \
	$ROOT_SNAPSHOT_DIR/./etc \
	$ROOT_SNAPSHOT_DIR/./root/keys \
	$ROOT_SNAPSHOT_DIR/./var \
	--exclude '*cache*' \
	--exclude '*/var/lib/libvirt/images/*' \
	--exclude '*/var/db/pkg/*' \
	--exclude '*/var/db/repos/*' \
	--exclude '*/var/lib/flatpak/repo/objects/*' \
	--exclude '*/var/tmp/*' \
	--show-rc \
	--stats \
	--progress \
	-C zstd,8

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-*' matching is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

if [ -d $HOME_SNAPSHOT_DIR ];then
	borg prune \
		--list \
		--glob-archives 'home-*' \
		--show-rc \
		--keep-daily 7 \
		--keep-weekly 4 \
		--keep-monthly 6
fi

borg prune \
	--list \
	--glob-archives 'root-*' \
	--show-rc \
	--keep-daily 7 \
	--keep-weekly 4 \
	--keep-monthly 6

prune_exit=$?

# actually free repo disk space by compacting segments

info "Compacting repository"

borg compact

compact_exit=$?

# use highest exit code as global exit code
global_exit=$((backup_exit > prune_exit ? backup_exit : prune_exit))
global_exit=$((compact_exit > global_exit ? compact_exit : global_exit))

if [ ${global_exit} -eq 0 ]; then
	info "Backup, Prune, and Compact finished successfully"
elif [ ${global_exit} -eq 1 ]; then
	info "Backup, Prune, and/or Compact finished with warnings"
else
	info "Backup, Prune, and/or Compact finished with errors"
fi

exit ${global_exit}
