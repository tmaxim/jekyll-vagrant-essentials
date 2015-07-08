#!/bin/bash
#
# This provisioning script has been derived from Varying Vagrant Vagrants:
# https://github.com/Varying-Vagrant-Vagrants/VVV

start_seconds="$(date +%s)"
echo "Welcome to the initialization script."

# Network Detection
#
# Make an HTTP request to google.com to determine if outside access is available
# to us. If 3 attempts with a timeout of 5 seconds are not successful, then we'll
# skip a few things further in provisioning rather than create a bunch of errors.
if [[ "$(wget --tries=3 --timeout=5 --spider http://google.com 2>&1 | grep 'connected')" ]]; then
  echo "Network connection detected..."
  ping_result="Connected"
else
  echo "Network connection not detected. Unable to reach google.com..."
  ping_result="Not Connected"
fi

apt_package_check_list=(
  vim
  curl
  git-core
  nodejs
)

# Loop through each of our packages that should be installed on the system. If
# not yet installed, it should be added to the array of packages to install.
apt_package_install_list=()

for pkg in "${apt_package_check_list[@]}"; do
  package_version="$(dpkg -s $pkg 2>&1 | grep 'Version:' | cut -d " " -f 2)"
  if [[ -n "${package_version}" ]]; then
    space_count="$(expr 20 - "${#pkg}")" #11
    pack_space_count="$(expr 30 - "${#package_version}")"
    real_space="$(expr ${space_count} + ${pack_space_count} + ${#package_version})"
    printf " * $pkg %${real_space}.${#package_version}s ${package_version}\n"
  else
    echo " *" $pkg [not installed]
    apt_package_install_list+=($pkg)
  fi
done

# If there are any packages to be installed in the apt_package_list array,
# then we'll run `apt-get update` and then `apt-get install` to proceed.
if [[ ${#apt_package_install_list[@]} = 0 ]]; then
  echo -e "No apt packages to install.\n"
else

  # Provides add-apt-repository (including for Ubuntu 12.10)
  sudo apt-get update --assume-yes > /dev/null
  sudo apt-get install --assume-yes python-software-properties
  sudo apt-get install --assume-yes software-properties-common

  sudo add-apt-repository -y ppa:git-core/ppa

  # Needed for nodejs.
  wget -q -O - https://deb.nodesource.com/setup | sudo bash -

  sudo apt-get update --assume-yes > /dev/null

  # install required packages
  echo "Installing apt-get packages..."
  sudo apt-get install --assume-yes ${apt_package_install_list[@]}
  sudo apt-get clean
fi

# npm
#
# Make sure we have the latest npm version and the update checker module
# npm install -g npm
# npm install -g npm-check-updates

# Gulp
# npm install -g gulp

# Bower
# npm install -g bower

# http://rvm.io/rvm/install
gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable --ruby
source ~/.rvm/scripts/rvm

# Jekyll
gem install jekyll

# Vagrant should've created /srv/www according to the Vagrantfile,
# but let's make sure it exists even if run directly.
if [[ ! -d '/srv/www' ]]; then
  sudo mkdir '/srv/www'
fi

end_seconds="$(date +%s)"
echo "-----------------------------"
echo "Provisioning complete in "$(expr $end_seconds - $start_seconds)" seconds"
