#!/bin/sh

# Set up default Git configuration for "The Installer"
git config --global jbh-installer.license "proprietary"
git config --global jbh-installer.company-name "SGH informationstechnologie UG mbH"
git config --global jbh-installer.company-name-short "SGH"               
git config --global jbh-installer.company-url "http://www.sgh-it.eu/"    

# Directories
cd ~
mkdir www

#Install dependencies from composer.
# Extensions from Composer will be deployed after Magento has been installed
cd /vagrant
composer install --dev --prefer-dist --no-interaction --no-scripts
cd ~

# link project modman packages (src/modman imports others)
modman link ./src
modman deploy src --force

# Use n98-magerun to set up Magento (database and local.xml)
# CHANGE BASE URL AND MAGENTO VERSION HERE:
# use --noDownload if Magento core is deployed with modman or composer. Remove the line if there already is a configured Magento installation
n98-magerun install --dbHost="localhost" --dbUser="root" --dbPass="" --dbName="magento" --installSampleData=no --useDefaultConfigParams=yes --magentoVersionByName="magento-ce-1.9.1.0" --installationFolder="www" --baseUrl="http://magento.local/"

# Write permissions in media
chmod -R 0770 /home/vagrant/www/media

# Now after Magento has been installed, deploy all additional modules and run setup scripts
modman deploy-all --force
n98-magerun sys:setup:run

# Set up PHPUnit
cd www/shell
mysqladmin -uroot create magento_unit_tests
php ecomdev-phpunit.php -a install
php ecomdev-phpunit.php -a magento-config --db-name magento_unit_tests --base-url http://magento.local/

# Link local.xml from /etc, this overwrites the generated local.xml
# from the install script. If it does not exist, the generated file gets copied to /etc first
# This way you can put the devbox local.xml under version control
if [ ! -f "/vagrant/etc/local.xml" ]; then
	cp ~/www/app/etc/local.xml /vagrant/etc/local.xml
fi
if [ ! -f "/vagrant/etc/local.xml.phpunit" ]; then
	cp ~/www/app/etc/local.xml.phpunit /vagrant/etc/local.xml.phpunit
fi
ln -fs /vagrant/etc/local.xml ~/www/app/etc/local.xml
ln -fs /vagrant/etc/local.xml.phpunit ~/www/app/etc/local.xml.phpunit

# Some devbox specific Magento settings
n98-magerun admin:user:create fschmengler fschmengler@sgh-it.eu test123 Fabian Schmengler
n98-magerun config:set dev/log/active 1