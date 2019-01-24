#!/bin/bash
# Create and upload asset to official release on GitHub.

#Credit where credit us due:
#Script to create release https://isabelcastillo.com/script-release-github
#Script to upload a release asset https://gist.github.com/stefanbuck/ce788fee19ab6eb0b4447a85fc99f447

# config
echo Enter GitHub access token:
read accessToken
echo Enter GitHub user name:
read gitUser
echo "Enter tag of new release (Good Practice: start version with 'v'):"
read tag
repoName=${PWD##*/} # name of your GitHub repository
assetFileName=${repoName}"-"$tag.zip

#check if in a repo(?)
#localRepoPath=`pwd` # this file should be in the base of your local git repository

#Test for valid Access Token
accessTokenStatus=$(curl -o -I -s -w "%{http_code}" -H "Authorization: token $accessToken" https://api.github.com)
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

#Test for plausible id
if [ "$id" == "" ]; then
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
