#!/bin/sh

set -e # -e: exit on error

is_macos () {
	[ "$(uname)" = "Darwin" ]
}
is_linux () {
	[ "$(uname)" = "Linux" ]
}

echo "[Step 1] Install programs"
if is_macos; then
	./install_homebrew.sh
	brew bundle
fi

if is_linux; then
	while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock > /dev/null 2>&1 ; do
		echo "Waiting for lock on apt-get to be released"
		sleep 1
	done
	sudo apt-get update
	sudo xargs -a debian-packages.txt apt-get install -y

	# Additional downloads
	sudo mkdir -p /usr/local/opt
	sudo chmod a+w /usr/local/opt

	# Install zplug for linux system
	export ZPLUG_HOME="/usr/local/opt/zplug"
	git clone https://github.com/zplug/zplug.git /usr/local/opt/zplug

	# Install diff-so-fancy for linux systems
	git clone https://github.com/so-fancy/diff-so-fancy.git /usr/local/opt/diff-so-fancy
	sudo ln -s /usr/local/opt/diff-so-fancy/diff-so-fancy /usr/local/bin/diff-so-fancy

  # Install chezmoi
  if [ ! "$(command -v chezmoi)" ]; then
    bin_dir="$HOME/.local/bin"
    chezmoi="$bin_dir/chezmoi"
    if [ "$(command -v curl)" ]; then
      sh -c "$(curl -fsLS https://git.io/chezmoi)" -- -b "$bin_dir"
    elif [ "$(command -v wget)" ]; then
      sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "$bin_dir"
    else
      echo "To install chezmoi, you must have curl or wget installed." >&2
      exit 1
    fi
  else
    chezmoi=chezmoi
  fi
fi

# Finish installing chezmoi
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
exec "$chezmoi" init --apply "--source=$script_dir"