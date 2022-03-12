#!/bin/sh

### CONFIGURATION
# get the zone here: https://www.ntppool.org/zone
NTP_SERVER="0.au.pool.ntp.org"
name=$(whoami)
chezmoi_user="karimone"

[ -z "$progsfile" ] && progsfile="progs.csv"
[ -z "$aurhelper" ] && aurhelper="yay"

### FUNCTIONS ###

installpkg(){ sudo pacman --noconfirm --needed -S "$1";}

error() { printf "%s\n" "$1" >&2; exit 1; }

setuser() { \
	# Adds user `$name` with password $pass1.
	useradd -m -g wheel -s /bin/zsh "$name" >/dev/null 2>&1 ||
	usermod -a -G wheel "$name" && mkdir -p /home/"$name" && chown "$name":wheel /home/"$name"
	export repodir="/home/$name/.local/src"; mkdir -p "$repodir"; chown -R "$name":wheel "$(dirname "$repodir")"
}

refreshkeys() { \
	case "$(readlink -f /sbin/init)" in
		*systemd* )
			pacman --noconfirm -S archlinux-keyring
			;;
		*)
			pacman --noconfirm --needed -S artix-keyring artix-archlinux-support
			for repo in extra community; do
				grep -q "^\[$repo\]" /etc/pacman.conf ||
					echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
			done
			pacman-key --populate archlinux
			;;
	esac ;}

newperms() { # Set special sudoers settings for install (or after).
	sed -i "/#LARBS/d" /etc/sudoers
	echo "$* #LARBS" >> /etc/sudoers ;}

manualinstall() { # Installs $1 manually. Used only for AUR helper here.
	# Dependency: Should be run after repodir is created and var is set.
	nodialog --infobox "Installing \"$1\", an AUR helper..." 4 50
	sudo -u "$name" mkdir -p "$repodir/$1"
	sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$repodir/$1" ||
		{ cd "$repodir/$1" || return 1 ; sudo -u "$name" git pull --force origin master;}
	cd "$repodir/$1"
	sudo -u "$name" -D "$repodir/$1" makepkg --noconfirm -si || return 1
}

maininstall() { # Installs all needed programs from main repo.
	echo "Installing \`$1\` ($n of $total). $1 $2"
	installpkg "$1"
	}

gitmakeinstall() {
	progname="$(basename "$1" .git)"
	dir="$repodir/$progname"
	sudo -u "$name" git clone --depth 1 "$1" "$dir" || { cd "$dir" || return 1 ; sudo -u "$name" git pull --force origin master;}
	cd "$dir" || exit 1
	make
	make install
	cd /tmp || return 1 ;}

aurinstall() { \
	echo "Installing \`$1\` ($n of $total) from the AUR. $1 $2"
	echo "$aurinstalled" | grep -q "^$1$" && return 1
	sudo -u "$name" $aurhelper -S --noconfirm "$1"
	}

pipinstall() { \
	echo "Installing the Python package \`$1\` ($n of $total). $1 $2"
	[ -x "$(command -v "pip")" ] || installpkg python-pip
	yes | pip install "$1"
	}

installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qqm)
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep -q "^\".*\"$" && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"A") aurinstall "$program" "$comment" ;;
			"G") gitmakeinstall "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
			*) maininstall "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;}

systembeepoff() {
  if [ ! -f /etc/modprobe.d/nobeep.conf ]
  then
    echo "Get rid of the system beep"
    rmmod pcspkr
    echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;
  fi
}


finalize() {
  echo "all done."
}

first_install() {
  # Install the packages and run some initial configurations

  # Refresh Arch keyrings.
  # TODO: it seems not helpful now. Remove?
  # refreshkeys || error "Error automatically refreshing Arch keyring. Consider doing so manually."

  for x in curl ca-certificates base-devel git ntp zsh ; do
    installpkg "$x"
  done

  echo "Update the date using $NTP_SERVER"
  ntpdate "$NTP_SERVER"

  [ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case

  # Allow user to run sudo without password. Since AUR programs must be installed
  # in a fakeroot environment, this is required for all builds with AUR.
  newperms "%wheel ALL=(ALL) NOPASSWD: ALL"

  # Make pacman colorful, concurrent downloads and Pacman eye-candy.
  grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
  sed -i "s/^#ParallelDownloads = 8$/ParallelDownloads = 5/;s/^#Color$/Color/" /etc/pacman.conf

  # Use all cores for compilation.
  sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

  setuser # prepare for the manual installation

  if [ ! -f /usr/bin/yay ];
  then
    manualinstall yay-bin || error "Failed to install AUR helper."
  fi

  # The command that does all the installing. Reads the progs.csv file and
  # installs each needed program the way required. Be sure to run this only after
  # the user has been created and has priviledges to run sudo without a password
  # and all build dependencies are installed.
  installationloop

  # Most important command! Get rid of the beep!
  systembeepoff

  # dbus UUID must be generated for Artix runit.
  dbus-uuidgen > /var/lib/dbus/machine-id

  # Use system notifications for Brave on Artix
  echo "export \$(dbus-launch)" > /etc/profile.d/dbus.sh

  # Tap to click
  [ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && printf 'Section "InputClass"
          Identifier "libinput touchpad catchall"
          MatchIsTouchpad "on"
          MatchDevicePath "/dev/input/event*"
          Driver "libinput"
    # Enable left mouse button by tapping
    Option "Tapping" "on"
  EndSection' > /etc/X11/xorg.conf.d/40-libinput.conf


  # Start/restart PulseAudio.
  pkill -15 -x 'pulseaudio'; sudo -u "$name" pulseaudio --start

  # This line, overwriting the `newperms` command above will allow the user to run
  # serveral important commands, `shutdown`, `reboot`, updating, etc. without a password.
  newperms "%wheel ALL=(ALL) ALL #LARBS
  %wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/packer -Syu,/usr/bin/packer -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/paru,/usr/bin/pacman -Syyuw --noconfirm"

  # enable bluetooth
  echo "enabling bluetooth"
  systemctl enable bluetooth
  systemctl start bluetooth

  # Last message! Install complete!
  finalize
  clear
}


set_chezmoi() {
  # log in bitwarden and execute the export of the BW_SESSION token
  eval "$(bw login | grep export | sed 's/$ //')"
  chezmoi init $chezmoi_user --apply
}


set_repositories() {
  code_path="$HOME/Code"
  wallpapers_path="$HOME/Pictures"
  documents_path="$HOME/Documents"

  cd "$code_path"
  mkdir -p "$code_path" && cd "$code_path"
  mkdir octopus && cd octopus
  git clone git@github.com:octoenergy/kraken-core.git
  git clone git@github.com:octoenergy/kraken-vagrant.git
  git clone git@github.com:octoenergy/handbook.git
  git clone git@github.com:octoenergy/aus-sdr.git chroma
  git clone git@github.com:octoenergy/octocloud.git

  cd "$code_path" && mkdir feex && cd feex
  git clone git@github.com:feex-au/mario-project.git
  git clone git@github.com:feex-au/feex-website.git
  git clone git@github.com:feex-au/lambda.git

  cd "$code_path" && mkdir websites && cd websites
  git clone git@gitlab.com:karimone/gorjux.net.git
  git clone git@gitlab.com:karimone/karimblog.git

  cd "$wallpapers_path"
  git clone git@github.com:karimone/newwallpapers.git wallpapers

  cd "$documents_path"
  git clone git@github.com:karimone/personal.git

}

# configure postgresql
# configure lightdm
# add `tig`

print_arguments() {
	  echo "Optional arguments for custom use:"
	  echo "  -h: Print this menu"
	  echo "  -i: Install packages from progs.csv and run the initial configuration"
	  echo "  -c: Set bitwarden and chezmoi"
	  echo "  -r: Set the repositories"
    exit 0;
}


while getopts ":icrh" o; do
  case "${o}" in
    i)
      first_install ;;
    c)
      set_chezmoi ;;
    r)
      set_repositories ;;
    h)
      print_arguments  ;;
    :)
      echo "due punti" ;;
    ?)
      printf "Invalid option: -%s\\n" "$OPTARG" && exit 1 ;;
  esac
done

