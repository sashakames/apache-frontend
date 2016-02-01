#!/bin/bash

quotedwsgipath=`echo "/opt/esgf/python/lib/python2.7/site-packages/mod_wsgi/server/mod_wsgi-py27.so"|sed 's/[./*?|"]/\\\\&/g'`
allowedips=`sed -n '/\#permitted-ips-start-here/,/\#permitted-ips-end-here/p' /etc/httpd/conf/esgf-httpd.conf|grep Allow|sort -u`;
sed "s/\#permitted-ips-end-here/\#permitted-ips-end-here\n\t\#insert-permitted-ips-here/" /etc/httpd/conf/esgf-httpd.conf >etc/httpd/conf/esgf-httpd.conf;
sed -i '/\#permitted-ips-start-here/,/\#permitted-ips-end-here/d' etc/httpd/conf/esgf-httpd.conf;
sed -i "s/\(.*\)LoadModule wsgi_module $quotedwsgipath\(.*\)/\1LoadModule wsgi_module placeholder_so\2/" etc/httpd/conf/esgf-httpd.conf;
incsfile=`echo Include /etc/httpd/conf/esgf-httpd-locals.conf|sed 's/[./*?|]/\\\\&/g'`;
incfile=`echo Include /etc/httpd/conf/esgf-httpd-local.conf|sed 's/[./*?|]/\\\\&/g'`;
uncommentedincfile=0
uncommentedincsfile=0
if ! grep -w 'Include /etc/httpd/conf/esgf-httpd-locals.conf' etc/httpd/conf/esgf-httpd.conf|grep '#' >/dev/null; then 
	uncommentedincsfile=1;
	sed -i "s/$incsfile/\#$incsfile/" etc/httpd/conf/esgf-httpd.conf;
fi
if ! grep -w 'Include /etc/httpd/conf/esgf-httpd-local.conf' etc/httpd/conf/esgf-httpd.conf|grep '#' >/dev/null; then 
	uncommentedincfile=1;
	sed -i "s/$incfile/\#$incfile/" etc/httpd/conf/esgf-httpd.conf;
fi
if ! diff etc/httpd/conf/esgf-httpd.conf.tmpl etc/httpd/conf/esgf-httpd.conf >/dev/null; then
	#we have changes; add allowed ips, ext file selection and wsgi path to latest template and apply
	echo "Detected changes. Will update and reapply customizations";
	cp etc/httpd/conf/esgf-httpd.conf.tmpl etc/httpd/conf/esgf-httpd.conf
	sed -i "s/\(.*\)LoadModule wsgi_module placeholder_so\(.*\)/\1LoadModule wsgi_module $quotedwsgipath\2/" etc/httpd/conf/esgf-httpd.conf;
	sed -i "s/\#insert-permitted-ips-here/\#permitted-ips-start-here\n$allowedips\n\t#permitted-ips-end-here/" etc/httpd/conf/esgf-httpd.conf;
	if [ $uncommentedincfile -eq 1 ]; then
		sed -i "s/\#$incfile/$incfile/" etc/httpd/conf/esgf-httpd.conf;
	fi
	if [ $uncommentedincsfile -eq 1 ]; then
		sed -i "s/\#$incsfile/$incsfile/" etc/httpd/conf/esgf-httpd.conf;
	fi
fi
		
	
