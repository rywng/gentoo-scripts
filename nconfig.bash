#!/usr/bin/env bash

export LLVM=1
export KCFLAGS='-march=native -pipe'
export KCPPFLAGS='-march=native -pipe'

set -e

kern_select () {
	realpath /usr/src/* | sort | uniq | fzf --no-sort --tac --prompt="$1"
}

pushd $(kern_select "Select target kernel >")

if [ ! -e .config ]; then
	cp $(kern_select "Select kernel to copy config file from")/.config .
	make oldconfig
fi

make nconfig

popd
