#!/bin/bash
# Create and upload asset to official release on GitHub.
#Arguments:
#-t, --token: github accsess token
#-u, --user: github user name
#-T, --tag: tag name, acts as release name
#
#the repo name is taken from root directory of this script 
#the built zip is 'hard' coded

#Credit where credit us due:
#parse arguments https://stackoverflow.com/a/29754866
#Script to create release https://isabelcastillo.com/script-release-github
#Script to upload a release asset https://gist.github.com/stefanbuck/ce788fee19ab6eb0b4447a85fc99f447



# argument handling
# saner programming env: these switches turn some bugs into errors
set -o errexit -o pipefail -o noclobber -o nounset

! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I’m sorry, `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=t:u:T:
LONGOPTS=token:,user:,tag:

# -use ! and PIPESTATUS to get exit code with errexit set
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

t=- user=- version=-
# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -t|--token)
            accessToken="$2"
            shift 2
            ;;
        -u|--user)
            gitUser="$2"
            shift 2
            ;;
        -T|--tag)
            tag="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

#make sure every argument is set (mind the "-" for handling unset var)
if [ -z "${accessToken-}" ]; then
	echo "Enter GitHub access token:"
	read accessToken
fi
if [ -z "${gitUser-}" ]; then
	echo "Enter GitHub user name:"
	read gitUser
fi
if [ -z "${tag-}" ]; then
	echo "Enter tag of new release (Good Practice: start version with 'v'):"
	read tag
fi

# /argument handling


# config
repoName=${PWD##*/} # name of your GitHub repository
assetFileName=${repoName}"-"$tag.zip

#check if in a repo(?)
#localRepoPath=`pwd` # this file should be in the base of your local git repository

#Test for valid Access Token
accessTokenStatus=$(curl -o /dev/null -I -s -w "%{http_code}" -H "Authorization: token $accessToken" https://api.github.com)
if [ $accessTokenStatus -eq 200 ]; then
	echo "Access token is valid ($accessTokenStatus)"
elif [ $accessTokenStatus == 401 ];then
	echo "Access token is invalid ($accessTokenStatus)"
	echo abort
	exit
else 
	echo "Access token unkown status ($accessTokenStatus)"
	echo abort
	exit
fi

exit

echo
echo ".........................................."
echo "1/3: Building Release Asset "$assetFileName
echo ".........................................."
echo
zip -r $assetFileName firmware-update META-INF

#Test zip exit code
zipExitCode=$?
if [ "$zipExitCode" != 0 ]; then
	echo "zip exit code zipExitCode"
	echo abort
	exit
else
	echo "Release file zipped successfully"
fi



echo
echo ".........................................."
echo "2/3: Creating Release "$tag
echo ".........................................."
echo
#cd "$localRepoPath"
jsonCreateRelease=$(printf '{"tag_name": "'$tag'","target_commitish": "master","name": "'$tag'","draft": false,"prerelease": false}' $tag $tag $tag)
id=$(curl --data "$jsonCreateRelease" https://api.github.com/repos/${gitUser}/${repoName}/releases?access_token=${accessToken} | grep -m 1 "id.:" | tr -cd [:digit:])
echo

#Test for plausible id
if [ -z "$id" ]; then
	echo "No id for new release tag received (unsuccessful?)"
	echo abort
	exit
else
	echo "Id for release tag is $id"
fi



echo
echo ".........................................."
echo "3/3: Adding Release Asset"
echo ".........................................."
echo
upload_url="https://uploads.github.com/repos/$gitUser/$repoName/releases/$id/assets?name=$(basename $assetFileName)"
curl -o /dev/null --data-binary @"$assetFileName" -H "Authorization: token $accessToken" -H "Content-Type: application/octet-stream" $upload_url
#TODO upload successful?
echo
echo " done 3/3"
