#!/usr/bin/env bash
set -e

# Arch Linux Install Script (alis) installs unattended, automated
# and customized Arch Linux system.
# Copyright (C) 2021 picodotdev

GITHUB_USER="karimone"
BRANCH="master"

while getopts "u:" arg; do
  case ${arg} in
    u)
      GITHUB_USER=${OPTARG}
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done

FILES=( "alis.conf" "alis.sh" "alis-reboot.sh" "alis-packages.conf" "alis-packages.sh" "alis-packages-exit.sh" "progs.csv" "larbs.sh")

for file in "${FILES[@]}"
do
  if [ -f "$file" ]; then
    echo "delete existing $file"
    rm -f "$file"
  fi
  url_file="https://raw.githubusercontent.com/$GITHUB_USER/alis/$BRANCH/$file"
  echo "download $url_file"
  curl -O "$url_file"
  chmod +x "$file"
done
