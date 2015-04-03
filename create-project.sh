#!/bin/bash

# This script creates a new project or Drupal site
# runs the installation script
# and prepares the apache vhost configuration files.

# Show help information about the script
project-usage() {
cat <<"USAGE"
Usage: create-project [OPTIONS]

	-h, --help        Show this help screen
	-r, --remove      Remove an existing project
	-l, --list        List the current virtual host

Examples:

	project foo
	project --remove foo
USAGE
exit 0
}

# Remove a project and its Virtual Host.
# project-remove() {
# }

# List the available and enabled virtual hosts.
# project-list() {
# }

# Set default values for the new project
PROJECT_NAME=
while [ -z "$PROJECT_NAME" ]; do
	read -p "Enter your project name: " PROJECT_NAME
done

EMAIL="support@agiledrop.com"
PROJECT_URL="$PROJECT_NAME.dev.agiledrop.com"
PROJECT_PATH="/var/www"

# Loop to read options and arguments.
while [ $1 ]; do
	case "$1" in
		'--list')
			project-list;;
		'--help'|'-h')
			project-usage;;
		'--remove'|'-r')
			url="$2"
			project-remove;;
	esac
	shift
done

# Install new Drupal project
echo ""
echo "---------------------------------------"
echo "Downloading Drupal at $PROJECT_PATH ..."
echo "---------------------------------------"
echo ""

# Setup Drupal files
cd "$PROJECT_PATH"
drush dl drupal --drupal-project-rename="$PROJECT_NAME"

# Install Drupal
cd "$PROJECT_PATH/$PROJECT_NAME"

# Prompt user for additional information
echo ""
echo "--------------------------------------------"
echo "Initializing Drupal installation process ..."
echo "--------------------------------------------"
echo ""

DB_PASSWORD=
while [ -z "$DB_PASSWORD" ]; do
	read -s -p "Enter mysql root login password: " DB_PASSWORD
done

# Do the core install
DB_USER="root"
DB_URL="mysql://$DB_USER:$DB_PASSWORD@localhost/$PROJECT_NAME"

drush si -y --account-mail="$EMAIL" --account-name=agileadmin --site-name="$PROJECT_NAME" --site-mail="$EMAIL" --db-url="$DB_URL"

# Set files folder permissions
chmod -R 777 "$PROJECT_PATH/$PROJECT_NAME/sites/default/files"

# Create the apache configuration file
echo ""
echo "--------------------------------------------"
echo "Creating a new apache configuration file ..."
echo "--------------------------------------------"
echo ""

cat <<EOF > /etc/apache2/sites-available/$PROJECT_NAME.conf
<VirtualHost *:80>

	ServerAdmin $EMAIL
	ServerName $PROJECT_URL
	DocumentRoot $PROJECT_PATH/$PROJECT_NAME

	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>

	<Directory $PROJECT_PATH/$PROJECT_NAME>
		Options FollowSymLinks MultiViews
		AllowOverride All
		Require all granted
	</Directory>

	ErrorLog /var/log/apache2/$PROJECT_NAME-error.log
	LogLevel error
	CustomLog /var/log/apache2/$PROJECT_NAME-access.log combined

</VirtualHost>
EOF

echo "Created new vhost file $PROJECT_NAME.conf at /etc/apache2/sites-available."

# Enable the new vhost and restart apache
echo ""
echo "---------------------------------------------------------"
echo "Enabling new configuration file and restarting apache ..."
echo "---------------------------------------------------------"
echo ""

a2ensite $PROJECT_NAME.conf
service apache2 restart

echo ""
echo "-------------------------------------------------"
echo "Your new project has been successfully installed."
echo "You can access the site from $PROJECT_URL."
echo "-------------------------------------------------"
echo ""

exit 0