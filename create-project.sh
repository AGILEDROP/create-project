#!/bin/bash

# This script creates a new project or Drupal site
# runs the installation script
# and prepares the apache vhost configuration files.

# Show help information about the script
project-usage() {
cat <<"USAGE"
Usage: create-project [OPTIONS]

	-h, --help        Show this help screen
	-c, --create      Creates a new project
	-l, --list        List the current virtual host
	-r, --remove      Remove an existing project

Examples:

	project --create foo
	project --remove foo
USAGE
exit 0
}

# Remove a project folder and its Apache vhost file
project-remove() {
	# Do a confirmation check before continuing
	while true; do
		read -p "This will remove you files, database and Apache vhost file. Do you wish to continue? (y/n): " yn
		case $yn in
			[Yy]* )
				break
				;;
			[Nn]* )
				exit 0
				;;
			* )
				echo "Please answer yes or no."
				;;
		esac
	done

	echo ""
	echo "---------------------------------------"
	echo "Removing $1 from projects folder, apache vhost file and database ..."
	echo "---------------------------------------"
	echo ""

	# Remove the files in the folder
	sudo rm -rf $PROJECT_PATH/$PROJECT_NAME
	echo "Removed project from $PROJECT_PATH/$PROJECT_NAME."

	# Remove the database
	DB_PASSWORD=
	while [ -z "$DB_PASSWORD" ]; do
		read -s -p "Enter mysql root login password: " DB_PASSWORD
	done
	mysql -u root -p"$DB_PASSWORD" -e "DROP database $PROJECT_NAME"
	echo "Dropped database $PROJECT_NAME from mysql."

	# Disable and remove the apache vhost file
	a2dissite "$PROJECT_NAME"
	rm -f $APACHE_PATH/$PROJECT_NAME.conf
	service apache2 restart
	echo "Removed Apache $PROJECT_NAME.conf file and restarted apache2 service."

	echo ""
	echo "---------------------------------------"
	echo "The project $PROJECT_NAME has now been completely removed."
	echo "---------------------------------------"
	echo ""

	exit 0
}

# List all projects inside the projects folder.
project-list () {
	echo ""
	echo "---------------------------------------"
	echo "Your installed projects ..."
	echo "---------------------------------------"
	echo ""
	ls -l "$PROJECT_PATH"
	echo ""

	exit 0
}

# Define some basic variables
EMAIL="support@agiledrop.com"
PROJECT_PATH="/var/www"
APACHE_PATH="/etc/apache2/sites-available"

# Loop to read options and arguments.
while [ $1 ]; do
	case "$1" in
		'--help'|'-h')
			project-usage
			;;
		'--create'|'-c')
			PROJECT_NAME="$2"
			;;
		'--list'|'-l')
			project-list
			;;
		'--remove'|'-r')
			if [ -z "$2" ]; then
				PROJECT_REMOVE=
				while [ -z "$PROJECT_REMOVE" ]; do
					read -p "Enter the name of the project to remove: " PROJECT_REMOVE
				done
			fi
			project-remove $PROJECT_REMOVE
			;;
	esac
	shift
done

# Ask for the project name if not specified in the arguments
while [ -z "$PROJECT_NAME" ]; do
	read -p "Enter your project name: " PROJECT_NAME
done

# Define project url
PROJECT_URL="$PROJECT_NAME.dev.agiledrop.com"

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

cat <<EOF > $APACHE_PATH/$PROJECT_NAME.conf
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

echo "Created new vhost file $PROJECT_NAME.conf at $APACHE_PATH."

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