#!/bin/bash

which xcode-select >/dev/null || noxcode="true"
if [ "$noxcode" == "true" ]; then
    echo "Make sure that you install Xcode via the App Store."
    echo "After it's installed, install the Xcode Command-Line Tools using:"
    echo "xcode-select --install"
    exit 1
fi

echo "Installing homebrew if needed..."
which brew >/dev/null || ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go/install)"
which brew >/dev/null || nobrew="true"
if [ "$nobrew" == "true" ]; then
    echo "brew failed to install..."
    exit 1
fi

#exit if any command exits non-zero
trap "echo something failed...; exit 1" ERR
set -o errexit
#set +o errexit
echo 1> setup-osx.log
export SETUP_LOG="`pwd`/setup-osx.log"

echo "Installing needed libraries and tools..."
brew install pkg-config
brew install autoconf
brew install boost --c++11 --build-from-source
brew tap homebrew/versions || true

echo "Installing pip..."
which pip >/dev/null || easy_install pip 1>>$SETUP_LOG
easy_install -U setuptools 1>>$SETUP_LOG

chk_pyv8=`python -c '
try:
    import PyV8
    print "found"
except:
    pass
'`
if [ "$chk_pyv8" != "found" ]; then
    echo 'Please wait, checking out subversion repo for [http://v8.googlecode.com/svn/trunk/]...'
    [ -d v8 ] && svn -q upgrade v8 2>/dev/null || true
    #svn checkout -r14110 http://v8.googlecode.com/svn/trunk/ v8 1>>$SETUP_LOG
    svn checkout http://v8.googlecode.com/svn/trunk/ v8 1>>$SETUP_LOG

    echo 'Patching V8...'
    cd v8
    patch --batch -p1 < ../../patches/V8-patch1.diff 1>>$SETUP_LOG
    cd ..

    echo 'Please wait, checking out subversion repo for [http://pyv8.googlecode.com/svn/trunk/]...'
    [ -d pyv8 ] && svn -q upgrade pyv8 2>/dev/null || true
    #svn checkout -r478 http://pyv8.googlecode.com/svn/trunk/ pyv8 1>>$SETUP_LOG
    svn checkout http://pyv8.googlecode.com/svn/trunk/ pyv8 1>>$SETUP_LOG

    echo 'Setting environment variable...'
    #export V8_HOME=`pwd`/v8
    echo "V8_HOME = \"$PWD/v8\"" > pyv8/buildconf.py
    #echo "DEBUG = True" >> pyv8/buildconf.py
    #echo "V8_SVN_REVISION = 14110" >> pyv8/buildconf.py
    #echo "BOOST_HOME = \"$(echo `pwd`/boost)\"" >> pyv8/buildconf.py
    #echo "BOOST_STATIC_LINK = True" >> pyv8/buildconf.py

    echo "Building PyV8 and V8(this may take several minutes)..."
    cd pyv8
    #patch -p0 < ../../patches/osx-setup.diff
    python setup.py build 2>&1 1>>$SETUP_LOG

    echo "Installing PyV8 and V8..."
    python setup.py install 1>>$SETUP_LOG
    cd ..
    python -c '
try:
    import PyV8
except:
    exit(1)
    '
fi

echo "Installing python libraries (beautifulsoup4, html5lib)..."
pip install beautifulsoup4 1>>$SETUP_LOG
pip install html5lib 1>>$SETUP_LOG

chk_pylibemu=`python -c '
try:
    import pylibemu
    print "found"
except:
    pass
'`
if [ "$chk_pylibemu" != "found" ]; then
    echo 'Please wait, cloning git repo for [git://git.carnivore.it/libemu.git]...'
    git clone -q git://git.carnivore.it/libemu.git 2>/dev/null 1>>$SETUP_LOG || true

    brew install gcc48
    echo "Configuring libemu..."
    cd libemu
    sed -i-orig -e 's/-no-cpp-precomp//' configure.ac
    sed -i-orig -e 's#/usr/lib/pkgconfig/#/usr/local/lib/pkgconfig/#' Makefile.am
    autoreconf -v -i 1>>$SETUP_LOG
    CC=gcc-4.8 CFLAGS="-w" ./configure --prefix=/usr/local --disable-shared 1>>$SETUP_LOG

    echo "Installing libemu..."
    make install 1>>$SETUP_LOG
    cd ..

    echo 'Please wait, cloning git repo for [git://github.com/buffer/pylibemu.git]...'
    git clone -q git://github.com/buffer/pylibemu.git 2>/dev/null 1>>$SETUP_LOG || true
    echo "Building pylibemu..."
    cd pylibemu
    sed -i-orig -e 's/distutils\.[^ ][^ ]* /setuptools /' setup.py
    python setup.py build 1>>$SETUP_LOG
    echo "Installing pylibemu..."
    python setup.py install 1>>$SETUP_LOG
    cd ..
    python -c '
try:
    import pylibemu
except:
    exit(1)
    '
fi

echo "Installing python libraries..."
echo "Installing python library: pefile..."
pip install pefile 1>>$SETUP_LOG

echo "Installing python library: chardet..."
pip install chardet 1>>$SETUP_LOG

echo "Installing python library: httplib2..."
pip install httplib2 1>>$SETUP_LOG

echo "Installing python library: cssutils..."
pip install cssutils 1>>$SETUP_LOG

echo "Installing python library: zope..."
pip install zope.interface 1>>$SETUP_LOG

echo "Installing python library: cssutils..."
pip install cssutils 1>>$SETUP_LOG

echo "Installing graphviz..."
brew install graphviz

echo "Installing python libraries..."
echo "Installing python library: pyparsing==1.5.7..."
easy_install pyparsing==1.5.7

echo "Installing python library: pydot..."
pip install pydot 1>>$SETUP_LOG

echo "Installing python library: python-magic..."
brew install libmagic 1>>$SETUP_LOG
pip install python-magic 1>>$SETUP_LOG
pip install libmagic 1>>$SETUP_LOG

echo "Installing python library: jsbeautifier..."
pip install jsbeautifier 1>>$SETUP_LOG

echo "Installing python library: yara..."
brew install yara 1>>$SETUP_LOG
pip install yara 1>>$SETUP_LOG

which mongo >/dev/null || nomongo="true"
if [ "$nomongo" == "true" ]; then
    echo -n "Install MongoDB?(y/n): "
    read response
    if [ "$response" = "y" ]; then
        echo "Installing MongoDB & PyMongo..."
        brew install mongodb 1>>$SETUP_LOG || true
        pip install pymongo 1>>$SETUP_LOG
    fi
fi

which rabbitmq-server >/dev/null || norabbitmq="true"
if [ "$norabbitmq" == "true" ]; then
    echo -n "Install RabbitMQ?(y/n): "
    read response
    if [ "$response" = "y" ]; then
        echo "Installing RabbitMQ & pika..."
        brew install rabbitmq 1>>$SETUP_LOG
        pip install pika 1>>$SETUP_LOG
    fi
fi
