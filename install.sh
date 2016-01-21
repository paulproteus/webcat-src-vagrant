#!/bin/sh
cd `dirname $0`
set -e

echo -n 'Looking for javac... '
if [ ! -f /usr/bin/javac ] ; then
    echo -n '... not found. Installing packages... '
    # Need to update or else the installs won't work. Failing is not critical.
    sudo DEBIAN_FRONTEND=noninteractive apt-get -qq update

    # Downgrade tzdata, hilarious.
    sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install --force-yes -y tzdata/trusty || (echo 'Failed to install tzdata.' ; exit 1)

    # Some things we need to build Web-CAT.
    sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install -y openjdk-7-jre openjdk-7-jdk ant git || (echo 'Failed to install required packages.' ; exit 1)
fi
echo 'Done!'

fetch()
{
	url="$1"
	file="`basename $url`"

	curl -sSL "$url" -o "$file.tmp" && mv "$file.tmp" "$file" || (echo 'Failed to download $file.' ; exit 1)
}

# install WebObjects
echo -n 'Installing WebObjects (root access required)... '
[ -f WOInstaller.jar ] || fetch http://wocommunity.org/tools/WOInstaller.jar
wodir=/Library/WebObjects/Versions/WebObjects543
sudo mkdir -p "$wodir"
[ -d "$wodir/Library/Frameworks/JavaXML.framework" ] || (sudo java -jar WOInstaller.jar 5.4.3 "$wodir" >/dev/null || (sudo rm -rf "$wodir" && echo 'Unable to install WebObjects.' && exit 1))
echo 'Done!'

# install Wonder Frameworks
echo -n 'Installing Wonder Frameworks (root access required)... '
[ -f Wonder-Frameworks.tar.gz ] || fetch https://github.com/wocommunity/wonder/releases/download/wonder-6.1.4/Wonder-Frameworks.tar.gz
sudo tar xfz Wonder-Frameworks.tar.gz -C "$wodir/Library/Frameworks"
echo 'Done!'

# woproject.jar is in the repository.
[ -f woproject.jar ] || fetch http://webobjects.mdimension.com/hudson/job/WOLips36Stable/lastSuccessfulBuild/artifact/woproject.jar
mkdir -p ~/.ant/lib
cp woproject.jar ~/.ant/lib

# wobuild.properties
echo -n 'Creating wobuild.properties... '
mkdir -p ~/Library/Frameworks
cat >~/Library/wobuild.properties << EOF
wo.wosystemroot=$wodir
wo.woroot=$wodir
wo.user.frameworks=$HOME/Library/Frameworks
wo.system.frameworks=$wodir/Library/Frameworks
wo.bootstrapjar=$wodir/Library/WebObjects/JavaApplications/wotaskd.woa/WOBootstrap.jar
wo.network.frameworks=/Network/Library/Frameworks
wo.api.root=/Library/WebObjects/ADC%20Reference%20Library/documentation/WebObjects/Reference/API
wo.network.root=/Network
wo.extensions=$wodir/Local/Library/WebObjects/Extensions
wo.user.root=$HOME
wo.local.frameworks=$wodir/Local/Library/Frameworks
wo.dir.local.library.frameworks=$wodir/Local/Library/Frameworks
wo.apps.root=$wodir/Local/Library/WebObjects/Applications
wo.wolocalroot=$wodir
wo.dir.user.home.library.frameworks=$HOME/Library/Frameworks
EOF
sudo chown -R $USER "$wodir/Library/Frameworks"
echo 'Done!'

# Retrieve the submodules
echo -n 'Retrieving submodules... '
git submodule init
git submodule update
echo 'Done!'

if [ "$#" -eq 0 ] || [ ! "$1" = "--install-only" ]; then
    read -p "Do you want to build Web-CAT? (y/n) " -n 1 -r
    echo #new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        ant -f web-cat/Web-CAT/build.xml build.subsystems build.redistributable.war
    fi
fi
