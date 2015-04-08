# Create project
Bash script for quickly creating a new Drupal project

## Currently supported features
* Creates a new Drupal project, database and Apache vhost file
* List all projects inside a folder
* Removes the project files, database and Apache vhost file

## Installation & usage
You install the script by placing it into a folder, that is also in your system $PATH, on your server and then calling it, preferably with a help of an alias.

### Recommended installation
Step by step instructions on how to install this script to your server. Ofcourse you can put it anywhere you wish and use it however you like.

First connect to your server via ssh.

```bash
# Go to your home directory
cd ~

# Create a folder if it doesnt exist already
mkdir .bin
chmod a+ .bin

# Install the script inside this folder
cd .bin
wget https://raw.githubusercontent.com/AGILEDROP/create-project/master/create-project.sh
chmod u+x create-project.sh
```

And thats it. Now you can simply call the script like so

```bash
sudo bash ~/.bin/create-project.sh
```

We can also create an alias for this for easier access. To do so we need to add the following line to our .profile file which should already be inside our home directory.

```bash
alias create-project='sudo bash ~/.bin/create-project.sh'
```

After that save the file, exit the editor and make sure your current session recognizes the new alias.

```bash
source .profile
```

### Usage
After installing it from the above instructions you can now use your new Drupal project creating. Use the -h or --help argument to show options.

```bash
create-project -h
```

## TO-DO
* ~~List function~~
* ~~Remove function~~
* Change owner:group of the files
* Update README.md file for better installation and usage instructions
* Initialize a git repository on creating a new project
* Bitbucket integrations to create a new repository
* Jenkins integration to create a build task