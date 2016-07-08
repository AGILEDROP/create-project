#!/bin/bash

# This script creates a new project or Drupal site
# runs the installation script
# and prepares the apache vhost configuration files.
# Requires the "realpath" package for the permissions script to run

# Show help information about the script
project-usage() {
cat <<"USAGE"
Usage: create-project [OPTIONS] <project-name>

	-h, --help        Show this help screen
	-c, --create      Creates a new project
	-l, --list        List the current virtual host
	-r, --remove      Remove an existing project

Examples:

	create-project --list
	create-project --create foo
	create-project --remove foo
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

	PROJECT_NAME=$1

	echo ""
	echo "---------------------------------------"
	echo "Removing $PROJECT_NAME project folder from $PROJECT_PATH ..."
	echo "---------------------------------------"
	echo ""

	# Remove the files in the folder
	sudo rm -rf $PROJECT_PATH/$PROJECT_NAME
	echo "Removed project folder $PROJECT_PATH/$PROJECT_NAME."

	echo ""
	echo "---------------------------------------"
	echo "Removing $PROJECT_NAME project database ..."
	echo "---------------------------------------"
	echo ""

	# Remove the database
	DB_PASSWORD=
	while [ -z "$DB_PASSWORD" ]; do
		read -s -p "Enter mysql root login password: " DB_PASSWORD
	done
	mysql -u root -p"$DB_PASSWORD" -e "DROP database $PROJECT_NAME"
	echo ""
	echo "Dropped database $PROJECT_NAME from mysql."

	echo ""
	echo "---------------------------------------"
	echo "Removing and disabling $PROJECT_NAME.conf from $APACHE_PATH ..."
	echo "---------------------------------------"
	echo ""

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

type -P realpath &>/dev/null && REALPATH_INSTALLED=1 || REALPATH_INSTALLED=0	# Checks if the realpath package is installed

if [ $REALPATH_INSTALLED = 1 ]; then	# Find the location of the script folder if realpath is installed
	SCRIPT=`realpath $0`
	SCRIPTPATH=`dirname $SCRIPT`
fi

# Loop to read options and arguments.
while [ $1 ]; do
	case "$1" in
		'--help'|'-h')
			project-usage
			;;
		'--create'|'-c')
			PROJECT_NAME="$2"
			PROJECT_ENV="$3"
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
				project-remove $PROJECT_REMOVE
			else
				project-remove $2
			fi
			;;
	esac
	shift
done

# Ask for the project name if not specified in the arguments
while [ -z "$PROJECT_NAME" ]; do
	read -p "Enter your project name: " PROJECT_NAME
done

# Ask for the project environment if not specified in the arguments
while [ "$PROJECT_ENV" != "prod" ] && [ "$PROJECT_ENV" != "dev" ]; do  # Chech if the input is correct
	read -p "Enter your project environment [DEV]/[prod]): " PROJECT_ENV
	if [ -z $PROJECT_ENV ]; then	# If the user presses enter choose the default environment "dev"
		PROJECT_ENV="dev"
	fi
	PROJECT_ENV=${PROJECT_ENV,,} # Make the input lower case
done


# Ask for jenkins usage
while [ "$JENKINS" != "y" ] && [ "$JENKINS" != "n" ]; do  # Chech if the input is correct
	read -p "Will Jenkins be used with this project? [Y]/[n]: " JENKINS
	if [ -z $JENKINS ]; then	# If the user presses enter choose the default option 'y'
		JENKINS="y"
	fi
	JENKINS=${JENKINS,,} # Make the input lower case
done

# Ask for existing project
while [ "$NEW" != "y" ] && [ "$NEW" != "n" ]; do  # Chech if the input is correct
	read -p "Do you want to initialize a clean install? [Y]/[n]: " NEW
	if [ -z $NEW ]; then	# If the user presses enter choose the default option 'y'
		NEW="y"
	fi
	NEW=${NEW,,} # Make the input lower case
done

# Ask for git repo URL
if [ "$NEW" = "n" ]; then	# It's an existing install
	while [ -z "$GIT_URL" ]; do
		read -p "Git clone url: " GIT_URL
	done

else		# It's a clean install

	# Ask for git initialization
	while [ "$USE_GIT" != "y" ] && [ "$USE_GIT" != "n" ]; do  # Chech if the input is correct
		read -p "Do you want to use git? [Y]/[n]: " USE_GIT
		if [ -z $USE_GIT ]; then	# If the user presses enter choose the default option 'y'
			USE_GIT="y"
		fi
		USE_GIT=${USE_GIT,,} # Make the input lower case
	done
	if [ "$USE_GIT" = "y" ]; then
		# Ask for existing repo
		while [ "$REPO_EXISTS" != "y" ] && [ "$REPO_EXISTS" != "n" ]; do  # Chech if the input is correct
			read -p "Do you already have an empty repository created? [y]/[N]: " REPO_EXISTS
			if [ -z $REPO_EXISTS ]; then	# If the user presses enter choose the default option 'y'
				REPO_EXISTS="n"
			fi
			REPO_EXISTS=${REPO_EXISTS,,} # Make the input lower case
		done
		# Ask for repo URL
		if [ "$REPO_EXISTS" = "y" ]; then
			while [ -z "$GIT_URL" ]; do
				read -p "Git clone url: " GIT_URL
			done
		else
			while [ -z "$GIT_USER" ]; do
				read -p "Bitbucket email: " GIT_USER
			done
			while [ -z "$GIT_PASS" ]; do
				read -s -p "Bitbucket password: " GIT_PASS
			done
			read -p "Repo owner username(agiledrop if empty): " REPO_OWNER
			if [ -z $REPO_OWNER ]; then
				REPO_OWNER="agiledrop"
			fi
		fi
	fi
fi



# Define project url
PROJECT_URL="$PROJECT_NAME.$PROJECT_ENV.agiledrop.com"

# Download the files
if [ $NEW = "y" ]; then
	# Install new Drupal project
	echo ""
	echo "---------------------------------------"
	echo "Downloading Drupal at $PROJECT_PATH ..."
	echo "---------------------------------------"
	echo ""

	# Setup Drupal files
	if [ $USE_GIT = "y" ]; then
		if [ $REPO_EXISTS = "y" ]; then
			cd "$PROJECT_PATH"
			mkdir "$PROJECT_NAME"
			git clone "$GIT_URL" ./"$PROJECT_NAME"/
		else	# Repo doesn't exist yet
			curl -X POST -v -u "$GIT_USER":"$GIT_PASS" -H "Content-Type: application/json" https://api.bitbucket.org/2.0/repositories/"$REPO_OWNER"/"$PROJECT_NAME" -d '{"scm": "git", "is_private": "true", "fork_policy": "no_public_forks" }'

			cd "$PROJECT_PATH"
			mkdir "$PROJECT_NAME"
			git clone git@bitbucket.org:"$REPO_OWNER"/"$PROJECT_NAME".git ./"$PROJECT_NAME"/
		fi
		# Git exists, now download Drupal and do the first commit
		cd "$PROJECT_PATH"
		sudo -u root drush dl drupal --drupal-project-rename="$PROJECT_NAME" -y
		sudo -u root cp "$PROJECT_PATH/$PROJECT_NAME"/example.gitignore "$PROJECT_PATH/$PROJECT_NAME"/.gitignore
		cd "$PROJECT_PATH/$PROJECT_NAME"
		pwd
		ls
		git add *
		git commit -m "Initial commit"
		git push --set-upstream origin master

	else	# Don't use git
		cd "$PROJECT_PATH"
		sudo -u root drush dl drupal --drupal-project-rename="$PROJECT_NAME" -y
	fi
	
else
	# Clone the repository
	mkdir "$PROJECT_PATH/$PROJECT_NAME"
	cd "$PROJECT_PATH/$PROJECT_NAME"
	git clone "$GIT_URL" ./
fi


# Install Drupal
cd "$PROJECT_PATH/$PROJECT_NAME"

# Prompt user for additional information
echo ""
echo "---------------------------------------"
echo "Initializing Drupal installation process ..."
echo "---------------------------------------"
echo ""

DB_PASSWORD=
while [ -z "$DB_PASSWORD" ]; do
	read -s -p "Enter mysql root login password: " DB_PASSWORD
done

# Do the core install
DB_USER="root"
DB_URL="mysql://$DB_USER:$DB_PASSWORD@localhost/$PROJECT_NAME"

drush si -y --account-mail="$EMAIL" --account-name=agileadmin --site-name="$PROJECT_NAME" --site-mail="$EMAIL" --db-url="$DB_URL"

# Set the folder permissions for the project
if [ $JENKINS = "y" ]; then
	PERMISSIONS_USER="jenkins"
else
	PERMISSIONS_USER="agiledrop"
fi

# Create the apache configuration file
echo ""
echo "---------------------------------------"
echo "Creating a new apache configuration file ..."
echo "---------------------------------------"
echo ""


if [ $PROJECT_ENV != "prod" ]
then
sudo -u root cat <<EOF > $APACHE_PATH/$PROJECT_NAME.conf
<VirtualHost *:80>

	ServerAdmin $EMAIL
	ServerName $PROJECT_URL
	DocumentRoot $PROJECT_PATH/$PROJECT_NAME

	Alias /robots.txt /var/www/robots.txt

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
else
sudo -u root cat <<EOF > $APACHE_PATH/$PROJECT_NAME.conf
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
fi

echo "Created new vhost file $PROJECT_NAME.conf at $APACHE_PATH."

# Enable the new vhost and restart apache
echo ""
echo "---------------------------------------"
echo "Enabling new configuration file and restarting apache ..."
echo "---------------------------------------"
echo ""

sudo -u root a2ensite $PROJECT_NAME.conf
sudo -u root service apache2 restart

echo ""
echo "---------------------------------------"
echo "Your new project has been successfully installed."
echo "You can access the site from $PROJECT_URL."
echo "---------------------------------------"
echo ""

if [ $REALPATH_INSTALLED = 1 ]; then
	sudo -u root sh $SCRIPTPATH/drupal-permissions.sh --drupal_path=$PROJECT_PATH/$PROJECT_NAME --drupal_user=$PERMISSIONS_USER
else
	echo ""
	echo "---------------------------------------"
	echo "Realpath is not installed, please run drupal-permissions.sh manually."
	echo "---------------------------------------"
	echo ""
fi

exit 0
