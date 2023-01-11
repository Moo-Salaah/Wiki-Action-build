#!/bin/sh

set -eu
WIKI_DIR='wiki'

TEMP_REPO_DIR="wiki_action_$GITHUB_REPOSITORY$GITHUB_SHA"
TEMP_WIKI_DIR="wiki_action_$GITHUB_REPOSITORY$WIKI_DIR$GITHUB_SHA"


if [ -z "$GH_TOKEN" ]; then
    echo "Token is not specified"
    exit 1
fi

if !(which node > /dev/null); then
    echo "node is not installed"
    exit 1
fi

#Clone repo
echo "Cloning repo https://github.com/$GITHUB_REPOSITORY"
git clone "https://$GITHUB_ACTOR:$GH_TOKEN@github.com/$GITHUB_REPOSITORY" "$TEMP_REPO_DIR"
cd "$TEMP_REPO_DIR"
#Clone wiki repo
echo "Cloning wiki repo https://github.com/$GITHUB_REPOSITORY.wiki.git"
git clone "https://$GITHUB_ACTOR:$GH_TOKEN@github.com/$GITHUB_REPOSITORY.wiki.git" "temp_$WIKI_DIR"

#build Wiki
npm ci
npm run docs
npm run html2md


#Get commit details
author=`git log -1 --format="%an"`
email=`git log -1 --format="%ae"`
message=`git log -1 --format="%s"`

echo "Copying edited wiki"
cp -R "temp_$WIKI_DIR/.git" "$WIKI_DIR/"

echo "Checking if wiki has changes"
cd "$WIKI_DIR"
git config --local user.email "$email"
git config --local user.name "$author" 
git add .
if git diff-index --quiet HEAD; then
  echo "Nothing changed"
  exit 0
fi

echo "Pushing changes to wiki"
git commit -m "$message" && git push "https://$GITHUB_ACTOR:$GH_TOKEN@github.com/$GITHUB_REPOSITORY.wiki.git"
