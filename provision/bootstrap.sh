#!/usr/bin/env bash
HOST_NAME="$(hostname)";

MYSQL_DB_NAME='vagrant';
MYSQL_DB_USER='vagrant';
MYSQL_DB_PASSWORD='vagrant';
MYSQL_ROOT_PASSWORD='vagrant';

TOOLS_USER='vagrant';
TOOLS_PASSWORD='vagrant';
TOOLS_PMA_BLOWFISH_KEY='vagrant';

SSL_CSR_INFO="
C=US
ST=$HOST_NAME
O=$HOST_NAME
localityName=$HOST_NAME
commonName=$HOST_NAME
organizationalUnitName=$HOST_NAME
emailAddress=vagrant@$HOST_NAME
";

SITE_NAME = 'chancegarcia';

# ---------------------------------------------
# ---------- Check Setup State ----------
# ---------------------------------------------

if [[ -f /etc/vagrant/.bootstrap-complete ]]; then

	service mysql restart;
#	service php5-fpm restart;
	service apache2 restart;

	exit 0; # Nothing more.

fi; # End conditional check.

# ---------------------------------------------
# ---------- Run Setup Routines ----------
# ---------------------------------------------

# Update package repositories.

# install python-software-properties to allow then add-apt-repository command
# install vim so we dont' get capital letter and other key weirdness with OSX
apt-get install -y python-software-properties vim
add-apt-repository multiverse;
apt-get update; # May take a moment.

# configure server time for logs
echo "America/Indiana/Indianapolis" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# configure locale information
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

# Install utilities.
apt-get install zip unzip git --yes;

# Install Apache web server.
apt-get install apache2 --yes;
apt-get install apache2-utils --yes;
apt-get install libapache2-mod-fastcgi --yes

# Configure apache web server
a2enmod rewrite
a2enmod ssl

sed --in-place 's/^\s*SSLProtocol all\s*$/SSLProtocol all -SSLv2 -SSLv3/I' /etc/apache2/mods-enabled/ssl.conf;
mkdir --parents /etc/vagrant/ssl;
echo "make dir in /var/www"
# make chancegarcia dir (allows access to provision file contents to cat for config and db initialization)
mkdir -p /var/www/chancegarcia.dev
echo "move original apache files"
a2dissite 000-default.conf
mv -v /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/zzz-default.conf.original
mv -v /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/zzz-default-ssl.conf.original
echo "copy apache conf files from synced folder"
cp -v /var/www/chancegarcia.dev/provision/etc/apache2/sites-available/chancegarcia.dev.conf /etc/apache2/sites-available/001-default.conf
cp -v /var/www/chancegarcia.dev/provision/etc/apache2/sites-available/ssl-chancegarcia.dev.conf /etc/apache2/sites-available/000-ssl_default.conf
#enable our sites and create associated log files
a2ensite 000-ssl_default.conf
a2ensite 001-default.conf

#no need to generate certs. just use existing ones given in provision directory
echo "make dir for apache ssl files"
mkdir -p /etc/apache2/ssl
echo "copy key and crt files from synced folder"
cp -v /var/www/chancegarcia.dev/provision/etc/apache2/ssl/* /etc/apache2/ssl/.
#openssl genrsa -out /etc/vagrant/ssl/.key 2048;
#openssl req -new -subj "$(echo -n "$SSL_CSR_INFO" | tr "\n" "/")" -key /etc/vagrant/ssl/.key -out /etc/vagrant/ssl/.csr -passin pass:'';
#openssl x509 -req -days 365 -in /etc/vagrant/ssl/.csr -signkey /etc/vagrant/ssl/.key -out /etc/vagrant/ssl/.crt;
sed -i '/AllowOverride None/c AllowOverride All' /etc/apache2/sites-available/000-default

# Install MySQL database server.

# need then debconf-set-selections first before mysql-server install; using pipe in case system doesn'then support here-strings
# http://stackoverflow.com/questions/7739645/install-mysql-on-ubuntu-without-password-prompt
echo 'mysql-server mysql-server/root_password password '"$MYSQL_DB_PASSWORD" | debconf-set-selections \
  && echo 'mysql-server mysql-server/root_password_again password '"$MYSQL_DB_PASSWORD" | debconf-set-selections \
	&& apt-get install -y mysql-server-5.6;
#export DEBIAN_FRONTEND=noninteractive
#echo 'mysql-server-5.6 mysql-server/root_password password '"$MYSQL_DB_PASSWORD" | debconf-set-selections
#echo 'mysql-server-5.6 mysql-server/root_password_again password '"$MYSQL_DB_PASSWORD" | debconf-set-selections
apt-get install -y mysql-server-5.6

# @todo fix to configure then mysql config
# If MySQL is installed, go through the various imports and service tasks.
#exists_mysql="$(service mysql status)"
#if [[ "mysql: unrecognized service" != "${exists_mysql}" ]]; then
#	echo -e "\nSetup MySQL configuration file links..."
#
#	# Copy mysql configuration from local
#	cp /srv/config/mysql-config/my.cnf /etc/mysql/my.cnf
#	cp /srv/config/mysql-config/root-my.cnf /home/vagrant/.my.cnf
#
#	echo " * Copied /srv/config/mysql-config/my.cnf               to /etc/mysql/my.cnf"
#	echo " * Copied /srv/config/mysql-config/root-my.cnf          to /home/vagrant/.my.cnf"
#
#	# MySQL gives us an error if we restart a non running service, which
#	# happens after a `vagrant halt`. Check to see if it's running before
#	# deciding whether to start or restart.
#	if [[ "mysql stop/waiting" == "${exists_mysql}" ]]; then
#		echo "service mysql start"
#		service mysql start
#	else
#		echo "service mysql restart"
#		service mysql restart
#	fi
#
#	# IMPORT SQL
#	#
#	# Create the databases (unique to system) that will be imported with
#	# the mysqldump files located in database/backups/
#	if [[ -f /srv/database/init-custom.sql ]]; then
#		mysql -u root -proot < /srv/database/init-custom.sql
#		echo -e "\nInitial custom MySQL scripting..."
#	else
#		echo -e "\nNo custom MySQL scripting found in database/init-custom.sql, skipping..."
#	fi
#
#	# Setup MySQL by importing an init file that creates necessary
#	# users and databases that our vagrant setup relies on.
#	mysql -u root -proot < /srv/database/init.sql
#	echo "Initial MySQL prep..."
#
#	# Process each mysqldump SQL file in database/backups to import
#	# an initial data set for MySQL.
#	/srv/database/import-sql.sh
#else
#	echo -e "\nMySQL is not installed. No databases imported."
#fi

# make directory for mysql log
mkdir --parents --mode=777 /var/log/mysql;
#ln --symbolic /vagrant/assets/mysql/.cnf /etc/mysql/conf.d/z90.cnf;

mysql_install_db; # Install database tables.

mysql --password="$MYSQL_DB_PASSWORD" --execute="GRANT ALL ON *.* TO '$MYSQL_DB_USER'@'localhost' IDENTIFIED BY '$MYSQL_DB_PASSWORD';";
mysql --password="$MYSQL_DB_PASSWORD" --execute="CREATE DATABASE \`$MYSQL_DB_NAME\` CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci';";

mysql --password="$MYSQL_DB_PASSWORD" --execute="DELETE FROM \`mysql\`.\`user\` WHERE \`User\` = '';";
mysql --password="$MYSQL_DB_PASSWORD" --execute="DELETE FROM \`mysql\`.\`user\` WHERE \`User\` = 'root' AND \`Host\` NOT IN ('localhost', '127.0.0.1', '::1');";
mysql --password="$MYSQL_DB_PASSWORD" --execute="DROP DATABASE IF EXISTS \`test\`; DELETE FROM \`mysql\`.\`db\` WHERE \`Db\` = 'test' OR \`Db\` LIKE 'test\\_%';";
mysql --password="$MYSQL_DB_PASSWORD" --execute="FLUSH PRIVILEGES;";

# Install PHP and PHP process manager.
apt-get install -y libapache2-mod-php5
apt-get install php5-cli --yes;
apt-get install php5-dev --yes;

apt-get install php5-curl --yes;
apt-get install php5-gd --yes;
apt-get install php5-imagick --yes;
apt-get install php5-json --yes;
apt-get install php5-mysql --yes;

apt-get install php5-mcrypt --yes;
echo 'extension=mcrypt.so' > /etc/php5/cli/conf.d/20-mcrypt.ini;
echo 'extension=mcrypt.so' > /etc/php5/fpm/conf.d/20-mcrypt.ini;

mkdir --parents --mode=777 /var/log/php;
#ln --symbolic /vagrant/assets/php/.ini /etc/php5/cli/conf.d/z90.ini;

echo '[www]' >> /etc/php5/fpm/pool.d/env.conf \
  && echo "env[MYSQL_DB_HOST] = 'localhost'" >> /etc/php5/fpm/pool.d/env.conf \
  && echo "env[MYSQL_DB_NAME] = '$MYSQL_DB_NAME'" >> /etc/php5/fpm/pool.d/env.conf \
  && echo "env[MYSQL_DB_USER] = '$MYSQL_DB_USER'" >> /etc/php5/fpm/pool.d/env.conf \
  && echo "env[MYSQL_DB_PASSWORD] = '$MYSQL_DB_PASSWORD'" >> /etc/php5/fpm/pool.d/env.conf;

# Create password file for web-based tools.

mkdir --parents /etc/vagrant/passwds;
htpasswd -cb /etc/vagrant/passwds/.tools "$TOOLS_USER" "$TOOLS_PASSWORD";

# Global environment variables.

echo "MYSQL_DB_HOST='localhost'" >> /etc/environment \
&& echo "MYSQL_DB_NAME='$MYSQL_DB_NAME'" >> /etc/environment \
&& echo "MYSQL_DB_USER='$MYSQL_DB_USER'" >> /etc/environment \
&& echo "MYSQL_DB_PASSWORD='$MYSQL_DB_PASSWORD'" >> /etc/environment \
&& echo "TOOLS_PMA_BLOWFISH_KEY='$TOOLS_PMA_BLOWFISH_KEY'" >> /etc/environment;

# xdebug install
apt-get install -y php-pear build-essential
mkdir /var/log/xdebug
chown www-data:www-data /var/log/xdebug
apt-get install -y php5-xdebug

php5enmod xdebug pdo pdo_mysql mcrypt curl gd imagick
# make apache php ini writable
chmod 744 /etc/php5/apache2/php.ini

# add xdebug to php configuration
echo "begin echo dump into apache php ini";
echo '' >> /etc/php5/apache2/php.ini
echo ';;;;;;;;;;;;;;;;;;;;;;;;;;' >> /etc/php5/apache2/php.ini
echo '; Added to enable Xdebug ;' >> /etc/php5/apache2/php.ini
echo ';;;;;;;;;;;;;;;;;;;;;;;;;;' >> /etc/php5/apache2/php.ini
echo '' >> /etc/php5/apache2/php.ini
#search in /usr/lib/php5 for then so file
echo 'zend_extension="'$(find /usr/lib/php5 -name 'xdebug.so' 2> /dev/null)'"' >> /etc/php5/apache2/php.ini
#cat php settings into then ini
cat /var/www/chancegarcia.dev/provision/etc/php.ini  >> /etc/php5/apache2/php.ini
echo '' >> /etc/php5/apache2/php.ini
echo 'xdebug.remote_host='$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10) >> /etc/php5/apache2/php.ini

echo "begin echo dump into cli php ini";
echo '' >> /etc/php5/cli/php.ini
echo ';;;;;;;;;;;;;;;;;;;;;;;;;;' >> /etc/php5/cli/php.ini
echo '; Added to enable Xdebug ;' >> /etc/php5/cli/php.ini
echo ';;;;;;;;;;;;;;;;;;;;;;;;;;' >> /etc/php5/cli/php.ini
echo '' >> /etc/php5/cli/php.ini
#search in /usr/lib/php5 for then so file
echo 'zend_extension="'$(find /usr/lib/php5 -name 'xdebug.so' 2> /dev/null)'"' >> /etc/php5/cli/php.ini
#cat php settings into then ini
cat /var/www/chancegarcia.dev/provision/etc/php.ini  >> /etc/php5/cli/php.ini
echo '' >> /etc/php5/cli/php.ini
echo 'xdebug.remote_host='$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10) >> /etc/php5/cli/php.ini

#@todo duplicate creating the vagrant mysql user case application user or just replace the variables since each application will now have it's own vagrant box
#@todo figure out how to read case directory and cat then contents of each sql file into the vagrant mysql db
#until we can script mysql provisioning, we can just copy files into then provision/sql directory to access and insert into then provisioned box

service mysql restart;
mysql -u $MYSQL_DB_USER --password=$MYSQL_DB_PASSWORD -v < /var/www/chancegarcia.dev/provision/sql/chancegarcia.sql

# Restart services.

service mysql restart;
service apache2 restart;

# allow vagrant user to work in adm,www-data groups
usermod -aG www-data,adm vagrant

# Mark setup as being complete.

touch /etc/vagrant/.bootstrap-complete;
