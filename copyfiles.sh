#!/bin/bash
TOMCATCONFDIR=$1
tomcatconfdir=${TOMCATCONFDIR:-"/usr/local/tomcat/conf"}

echo "What is the public name of the server? (no protocol part)";
read servername;
if [ "$servername" != "$HOSTNAME" ]; then
	echo "Provider server name $servername is different from the hostname $HOSTNAME. Is this ok?(y/n)";
	read response;
	if [ "$response" == "y" -o "$response" == "Y" ]; then
		ok=1;
	else
		ok=0
	fi
	if [ $ok -ne 1 ]; then
		exit -1;
	fi
fi
#echo "What is the truststore password? (default:changeit)";
#read truststorepass;
#if [ "$truststorepass" == "" ]; then
#	truststorepass="changeit";
#fi
#echo "What is the key alias? (default:my_esgf_node)";
#read keyalias;
#if [ "$keyalias" == "" ]; then
#	keyalias="my_esgf_node";
#fi
#keystorepass="";
#while(true); do
#	echo "What is the keystore password?";
#	read keystorepass;
#	if [ "$keystorepass" != "" ]; then
#		break;
#	fi
#done

esgfpip='NA'
esgfpython='NA'

tmpservername='placeholder.fqdn'
echo "Entered values:-";
echo -e "servername=$servername\ntruststorepass=$truststorepass\nkeyalias=$keyalias\nkeystorepass=$keystorepass";

quotedtmpservername=`echo "$tmpservername" | sed 's/[./*?|]/\\\\&/g'`;
quotedservername=`echo "$servername" | sed 's/[./*?|]/\\\\&/g'`;

quotedtmptrustpass=`echo "truststorePass=\"changeit\"" | sed 's/[./*?|"]/\\\\&/g'`;
quotedtmpkeyalias=`echo "keyAlias=\"my_esgf_node\""| sed 's/[./*?|"]/\\\\&/g'`;
quotedtmpkeypass=`echo "keystorePass=\"yourpasswordhere\""| sed 's/[./*?|"]/\\\\&/g'`;

quotedservername=`echo "$servername" | sed 's/[./*?|]/\\\\&/g'`;
quotedtrustpass=`echo "truststorePass=\"$truststorepass\""|sed 's/[./*?|"]/\\\\&/g'`;
quotedkeyalias=`echo "keyAlias=\"$keyalias\""|sed 's/[./*?|"]/\\\\&/g'`;
quotedkeypass=`echo "keystorePass=\"$keystorepass\""|sed 's/[./*?|"]/\\\\&/g'`;
quotedrunfile=`echo "/var/run/httpd/httpd.pid"|sed 's/[./*?|"]/\\\\&/g'`
quotedc5runfile=`echo "/var/run/httpd.pid"|sed 's/[./*?|"]/\\\\&/g'`
sed -i "s/\(.*\)$quotedtmpservername\(.*\)/\1$quotedservername\2/" $tomcatconfdir/server.xml;
#sed "s/\(.*\)$quotedtmptrustpass\(.*\)/\1$quotedtrustpass\2/" usr/local/tomcat/conf/1 >usr/local/tomcat/conf/2;
#sed "s/\(.*\)$quotedtmpkeyalias\(.*\)/\1$quotedkeyalias\2/" usr/local/tomcat/conf/2 >usr/local/tomcat/conf/3;
#sed "s/\(.*\)$quotedtmpkeypass\(.*\)/\1$quotedkeypass\2/" usr/local/tomcat/conf/3 >usr/local/tomcat/conf/server.xml;

sed "s/\(.*\)$quotedtmpservername\(.*\)/\1$quotedservername\2/" etc/httpd/conf/esgf-httpd.conf.tmpl >etc/httpd/conf/esgf-httpd.conf;
if grep -w 'release 5' /etc/redhat-release >/dev/null; then
	#this is a C5/RHEL5 machine. Adjust httpd conf
	echo "Adjusted httpd conf for C5/RHEL5";
	sed "s/\(.*\)$quotedrunfile\(.*\)/\1$quotedc5runfile\2/" etc/init.d/esgf-httpd.tmpl >etc/init.d/esgf-httpd;
	else
	cp etc/init.d/esgf-httpd.tmpl etc/init.d/esgf-httpd;
fi

bash setup_python.sh "$esgfpython" "$esgfpip";
cp etc/init.d/esgf-httpd /etc/init.d/
cp etc/httpd/conf/esgf-httpd.conf /etc/httpd/conf/
#cp usr/local/tomcat/conf/server.xml /usr/local/tomcat/conf/
mkdir -p /etc/certs
mkdir -p /opt/esgf/flaskdemo/demo
cp wsgi/demo/* /opt/esgf/flaskdemo/demo
chown -R apache:apache /opt/esgf/flaskdemo/demo
cp etc/certs/esgf-ca-bundle.crt /etc/certs/
rm -f etc/httpd/conf/esgf-httpd.conf
rm -f etc/init.d/esgf-httpd
