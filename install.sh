#!/bin/sh
export HOME=/home/vagrant

if [ ! -f /usr/bin/javac ] ; then
    # Need to update or else the installs won't work
    sudo DEBIAN_FRONTEND=noninteractive apt-get update

    # Downgrade tzdata, hilarious.
    sudo DEBIAN_FRONTEND=noninteractive apt-get install --force-yes -y tzdata/trusty

    # Some things we need to build Web-CAT.
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-7-jre openjdk-7-jdk ant git
fi

# install WebObjects
[ -f WOInstaller.jar ] || curl -# -O http://wocommunity.org/tools/WOInstaller.jar
wodir=/Library/WebObjects/Versions/WebObjects543
sudo mkdir -p $wodir
[ -d $wodir/Library/Frameworks/JavaXML.framework ] || sudo java -jar WOInstaller.jar 5.4.3 $wodir

# install Wonder Frameworks
[ -f Wonder-Frameworks.tar.gz ] || curl -# -O -L https://jenkins.wocommunity.org/job/Wonder/lastSuccessfulBuild/artifact/Root/Roots/Wonder-Frameworks.tar.gz
sudo tar xfz Wonder-Frameworks.tar.gz -C $wodir/Library/Frameworks

# woproject.jar
[ -f woproject.jar ] || curl -# -O http://webobjects.mdimension.com/hudson/job/WOLips36Stable/lastSuccessfulBuild/artifact/woproject.jar
mkdir -p ~/.ant/lib
cp woproject.jar ~/.ant/lib

# wobuild.properties
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
sudo chown -R vagrant $wodir/Library/Frameworks ~/Library

# If the source isn't checked out, check it out.
if [ ! -d web-cat ] ; then
    mkdir -p web-cat
    git clone https://github.com/mkhon/web-cat web-cat
fi

#(cd web-cat/Web-CAT && ant install.subsystems.and.build)
