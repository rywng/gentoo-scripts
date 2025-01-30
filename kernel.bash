#!/usr/bin/env bash

export LLVM=1
export KCFLAGS='-march=native -pipe'
export KCPPFLAGS='-march=native -pipe'
# Use ccache for kernel building
export PATH="/usr/lib/ccache/bin${PATH:+:}$PATH"
export KBUILD_BUILD_TIMESTAMP='' # Fix ccache not no hit

kernel_directory=$(realpath /usr/src/* | sort | uniq | fzf --no-sort --tac)
vcs_directory="/root/repos/kernel-vcs"
vcs_branch=$(qfile -q -F '%{PN}' $kernel_directory )

# This makes sure the @module-rebuild will properly build modules for new kernel
eselect kernel set $(basename $kernel_directory) && echo "default kernel is set to " $kernel_directory

if [ -z $kernel_directory ]; then
	exit 1
fi

cd $vcs_directory

git branch $vcs_branch; git switch $vcs_branch

cp $kernel_directory/.config $vcs_directory || echo "no config found" || exit 1

git commit -av

cd $kernel_directory

make LLVM=1 -j18 &&
	make LLVM=1 modules_install &&
	make LLVM=1 install || exit 1

emerge @module-rebuild -q --keep-going

btrbk -c /etc/btrbk/root.conf run

eclean-kernel -n2
