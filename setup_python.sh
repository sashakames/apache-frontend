#!/bin/bash

ESGFPYTHON="$1";
ESGFPIP="$2";
ORGDIR=`pwd`;
rm -rf tempbuildDIR 2>/dev/null;

onfail(){
	echo "$1";
	exit -1;
}
write_path_to_httpdconf(){
	nPATH="/opt/esgf/python/bin:$PATH"
	#echo "path=~$nPATH~";
	#echo "LD_LIBRARY_PATH=~$LD_LIBRARY_PATH~";
	quotednpath=`echo "$nPATH"|sed 's/[./*?|"]/\\\\&/g'`
	quotedldpath=`echo "$LD_LIBRARY_PATH"|sed 's/[./*?|"]/\\\\&/g'`
	quotedwsgipath=`echo "/opt/esgf/python/lib/python2.7/site-packages/mod_wsgi/server/mod_wsgi-py27.so"|sed 's/[./*?|"]/\\\\&/g'`
	cd $ORGDIR;
	sed -i "s/\(.*\)PATH=placeholderpath\(.*\)/\1PATH=$quotednpath\2/" etc/init.d/esgf-httpd;
	sed -i "s/\(.*\)LD_LIBRARY_PATH=placeholderldval\(.*\)/\1LD_LIBRARY_PATH=$quotedldpath\2/" etc/init.d/esgf-httpd;
	sed -i "s/\(.*\)LoadModule wsgi_module placeholder_so\(.*\)/\1LoadModule wsgi_module $quotedwsgipath\2/" etc/httpd/conf/esgf-httpd.conf;
}

custominstall_pip(){
	echo "$1";
	mkdir -p tempbuildDIR;
	cd tempbuildDIR;
	rm -rf /root/.cache/pip;
	wget --no-check-certificate https://bootstrap.pypa.io/ez_setup.py;
	EZ=`dirname $PYTHON`/easy_install;
	$PYTHON ez_setup.py --insecure
	$EZ pip
	PIP=`dirname $PYTHON`/pip
}

custominstall_python(){
	echo "$1";
	mkdir -p tempbuildDIR;
	cd tempbuildDIR;
	wget https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz;
	tar -xf Python-2.7.9.tgz;
	cd Python-2.7.9;
	./configure --prefix=/opt/esgf/python --enable-shared;
	make 2>&1 |tee make.out || onfail "make on python failed";
	make install || onfail "make install on python failed";
	echo "ORGDIR was $ORGDIR";
	PYTHON=/opt/esgf/python/bin/python2.7
	export LD_LIBRARY_PATH=/opt/esgf/python/lib:$LD_LIBRARY_PATH
	export CFLAGS="-I/opt/esgf/python/include/python2.7 -I/usr/include/httpd -I/usr/include -I/usr/include/apr-1 $CFLAGS";
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
cd $ORGDIR
env >apachef.env
mkdir -p /opt/esgf/virtual;
cd /opt/esgf/virtual;
VIRTENV=`dirname $PYTHON`/virtualenv;
$VIRTENV -p $PYTHON python --system-site-packages
/opt/esgf/python/bin/pip install flask;
/opt/esgf/python/bin/pip install mod_wsgi;
write_path_to_httpdconf
cd $ORGDIR && rm -rf tempbuildDIR
exit 0
