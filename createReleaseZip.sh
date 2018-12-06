#!/bin/bash
# Create official Release on GitHub.
 
# config
echo Enter GitHub access token:
read ACCESSTOKEN
echo Enter GitHub user name:
read GITUSER
NAME=${PWD##*/} # name of your GitHub repository
 
GITPATH=`pwd` # this file should be in the base of your local git repository
# Get version from readme
NEWVERSION=`grep "^Version" "$GITPATH/README.md" | awk -F' ' '{print $2}' | sed 's/[[:space:]]//g'`

# Let's begin...
echo ".........................................."
echo
echo "Preparing to release version $NEWVERSION on GitHub"
echo
echo ".........................................."
echo
 
# Create a Release on GitHub
cd "$GITPATH"
echo "Creating a new release on GitHub"
API_JSON=$(printf '{"tag_name": "v%s","target_commitish": "master","name": "v%s","body": "Release of version %s","draft": false,"prerelease": false}' $NEWVERSION $NEWVERSION $NEWVERSION)
curl --data "$API_JSON" https://api.github.com/repos/${GITUSER}/${NAME}/releases?access_token=${ACCESSTOKEN}
 
echo "*** FIN ***"
