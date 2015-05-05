#!/bin/bash

if [ ! -f /usr/bin/javac ] ; then
    # Need to update or else the installs won't work
    sudo DEBIAN_FRONTEND=noninteractive apt-get update

    # Downgrade tzdata, hilarious.
    sudo DEBIAN_FRONTEND=noninteractive apt-get install --force-yes -y tzdata/trusty

    # Some things we need to build Web-CAT.
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-7-jre openjdk-7-jdk cvs build-essential
fi

# If the source isn't checked out, check it out.
if [ ! -d /vagrant/source ] ; then
    mkdir -p /vagrant/source
    pushd /vagrant/source
    # CVS login, hilarious.
    cvs  -d:pserver:anonymous:@web-cat.cvs.sourceforge.net:/cvsroot/web-cat login
    # CVS checkout, hilarious.
    cvs -z3 -d:pserver:anonymous@web-cat.cvs.sourceforge.net:/cvsroot/web-cat co -P Web-CAT
    popd
fi
