# Notes during installation

First installation: when you boot and you run alis.sh
The packages are not installed after the first installation. 
You have to download again alis and run the alis packages

```shell
./alis-pachages.sh
```

The packages could be installed from a csv file like the other tool I use :-)

## Missing packages

## Installing chezmoi
```shell
yay -S chezmoi
```
Install first bitwarden and log in to get the decompression of the files!

Then you can install the dotfiles

```shell
yay -S bwcli
chezmoi init --apply karimone
```

## i3-gaps-rounded

My config uses `i3-gaps-rounded-git`
```shell
yay -S i3-gaps-rounded-git
```
then you can exit

```shell
i3msg exit
```

## Lightdm

Is it installed by alis by default. It's good but with a very ugly greeter.

```shell
yay -S lightdm-webkit-theme-aether-git
```
then restart lightdm

```shell
systemctl restart lightdm
```

## Bluetooth
The service must be enabled (something to add in the script

```shell
systemctl enable bluetooth
```

## PulseAudio
It must be installed (is missing from the scripts)

* pulseaudio
* pulseaudio-alsa
* pulseaudio-bluetooth

Not sure at the moment how is started the pulseaudio deamon, maybe a restart?
If you run `pulseaudio` you can use the audio and pair bluetooth devices

## Apple Keyboard (also Keychron)

The default of Apple is to have the media key and not the function. Keychron must have the switch set to Apple

If you want to revert this temporary:

```shell
echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode
```

If you want to do that permanently:

```shell
echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
```

More info [here](https://wiki.archlinux.org/title/Apple_Keyboard)

## Polybar collection

Install fonts:

* nerd-fonts-ubuntu-mono
* nerd-fonts-iosevka
* nerd-fonts-jetbrains-mono
* ttf-material-icons-git


## Fonts and polybar

The fonts are a pain in the ass. Bitmap fonts cannot be scaled on polybar

For example the siji font is available (here)[https://github.com/fauno/siji/blob/master/ttf/siji.ttf]
You can install the font in your `$HOME/.fonts/` directory and then

```shell
fc-cache -fvr  # update the font cache
fc-list | grep -i siji  # get the font name to use in polybar
```
There is a perl function that can help you understand what font can render the character
you have a problem to render. See (here)[https://github.com/polybar/polybar/wiki/Fonts#debugging-font-issues] the instructions at the point 3

## Clipboard

Use greenclip!

```
yay -Syu rofi-greenclip-git
```

The i3 configuration triggers the demon on loading and the rofi menu with mod+shift+c

## NTP autosync

Add this line if you need the sync on NTPD

```bash
systemctl status systemd-timesyncd
```

## XDG

Check the docs

## Packages

* brave-bin
* bashtop
* starship  # better than oh-my-zsh
* bitwarden bitwarden-cli
* zoom
* exa
* hugo
* compton
* playerctl
* udiskie
* xdotool
* xbindkeys, bind keys event to command. Useful for configure the mouse buttons
* zscroll-git
* xcompmgr
* thunar, file manager
* copyq, clipboard manager
* xdg-tools, 
* mimeo, tools for manage the mime/xdg association
* jq, json processor
* nvm, node virtual manager

## TODO:
* It could be nice to add a copy of alis downloaded on the install inside the $HOME user
* On the first boot I had to install `git` and `vim`, we can add it in the first installation
* yay is reinstalled (and any other aur) even if is already there
* 

