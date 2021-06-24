#!/usr/bin/env bash

# telling git where to run the commands from because the GIT_DIR enviroment
# variable was not set
gitDir=/var/www/bahmni_config_release/.git

# checks if something happened on the remote repo

git --git-dir=$gitDir fetch

# now see if there's anything that happened

git --git-dir=$gitDir diff HEAD remotes/origin/master

# Now get ONLY files that were edited. This will
# help in preserving bandwith

git --git-dir=$gitDir fetch origin
