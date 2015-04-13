#!/bin/bash

ESGFPYTHON="$1";
ESGFPIP="$2";
ORGDIR=`pwd`;
rm -rf /tmp/tempbuildDIR 2>/dev/null;

onfail(){
	echo "$1";
	exit -1;
}
write_path_to_httpdconf(){
	nPATH="/opt/esgf/virtual/python/bin:$PATH"
	#echo "path=~$nPATH~";
	#echo "LD_LIBRARY_PATH=~$LD_LIBRARY_PATH~";
	quotednpath=`echo "$nPATH"|sed 's/[./*?|"]/\\\\&/g'`
	quotedldpath=`echo "$LD_LIBRARY_PATH"|sed 's/[./*?|"]/\\\\&/g'`
	quotedwsgipath=`echo "/opt/esgf/virtual/python/lib/python2.7/site-packages/mod_wsgi/server/mod_wsgi-py27.so"|sed 's/[./*?|"]/\\\\&/g'`
	cd $ORGDIR;
	sed -i "s/\(.*\)PATH=placeholderpath\(.*\)/\1PATH=$quotednpath\2/" etc/init.d/esgf-httpd;
	sed -i "s/\(.*\)LD_LIBRARY_PATH=placeholderldval\(.*\)/\1LD_LIBRARY_PATH=$quotedldpath\2/" etc/init.d/esgf-httpd;
	sed -i "s/\(.*\)LoadModule wsgi_module placeholder_so\(.*\)/\1LoadModule wsgi_module $quotedwsgipath\2/" etc/httpd/conf/esgf-httpd.conf;
}

custominstall_pip(){
	echo "$1";
	mkdir -p /tmp/tempbuildDIR;
	cd /tmp/tempbuildDIR;
	export LD_LIBRARY_PATH=/opt/esgf/real/lib:$LD_LIBRARY_PATH
	wget --no-check-certificate https://bootstrap.pypa.io/ez_setup.py;
	$PYTHON ez_setup.py --insecure
	wget --no-check-certificate https://pypi.python.org/packages/source/p/pip/pip-6.1.1.tar.gz
	tar -xf pip-6.1.1.tar.gz
	cd pip-6.1.1
	$PYTHON setup.py install
	PIP=`dirname $PYTHON`/pip
}

custominstall_python(){
	echo "$1";
	mkdir -p /tmp/tempbuildDIR;
	cd /tmp/tempbuildDIR;
	wget https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz;
	tar -xf Python-2.7.9.tgz;
	cd Python-2.7.9;
	./configure --prefix=/opt/esgf/real --enable-shared;
	make 2>&1 |tee make.out || onfail "make on python failed";
	make install || onfail "make install on python failed";
	PYTHON=/opt/esgf/real/bin/python2.7
	export LD_LIBRARY_PATH=/opt/esgf/real/lib:$LD_LIBRARY_PATH
}

if [ ! -e $ESGFPYTHON ]; then
	custominstall_python "python not found at $ESGFPYTHON. Will now custom-install";
	else 
	PYTHON=$ESGFPYTHON;
fi 

if [ ! -e $ESGFPIP ]; then
	custominstall_pip "pip not found at $ESGFPIP. Will now custom-install";
	else 
	PIP=$ESGFPIP;
	LOCAL_LD=`dirname $PYTHON`/../lib;
	LL=`echo $LOCAL_LD|sed 's/bin\/\.\.\///g'`;
	if [ "$LD_LIBRARY_PATH" = "" ]; then
		export LD_LIBRARY_PATH=$LL:
	fi
fi 
$PIP install virtualenv
mkdir -p /opt/esgf/virtual;
cd /opt/esgf/virtual;
VIRTENV=`dirname $PYTHON`/virtualenv;
$VIRTENV -p $PYTHON python --system-site-packages
/opt/esgf/virtual/python/bin/pip install flask;
/opt/esgf/virtual/python/bin/pip install mod_wsgi;
write_path_to_httpdconf
exit 0
