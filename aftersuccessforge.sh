#!/bin/bash -e
# Based on Chris Down's travis-automerge script (https://github.com/cdown/travis-automerge)

: "${GITHUB_SECRET_TOKEN?}"

export GIT_COMMITTER_EMAIL='travis@travis'
export GIT_COMMITTER_NAME='Travis CI'

export SHA=$(curl https://api.github.com/repos/$TRAVIS_REPO_SLUG/pulls/$TRAVIS_PULL_REQUEST |jq -r .head.sha)
export MESSAGE="Merged automatically by Travis CI. Full testing details on https://travis-ci.org/$TRAVIS_REPO_SLUG/jobs/$TRAVIS_BUILD_ID"
# I just want to do one merge, so I'm checking I'm running in the right Travis Job (Environment)
if [ "$PUPPET_GEM_VERSION" = "~> 4.3" ]; then
	if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
	    	printf "This is not a Pull Request, I won't be deploying this. Exiting\\n"
	        exit 0
	fi

	printf "SHA of the Commit is $SHA\n"
	printf "Merging PR# $TRAVIS_PULL_REQUEST with message $MESSAGE\n"
	MERGE=$(curl -X PUT --data "{\"commit_message\":\"$MESSAGE\",\"sha\":\"$SHA\"}" https://$GITHUB_SECRET_TOKEN@api.github.com/repos/$TRAVIS_REPO_SLUG/pulls/$TRAVIS_PULL_REQUEST/merge | jq -r .merged)
	printf "Merge status is $MERGE"
	if [ $MERGE = true ]; then
		printf "go and deploy stuff"
		echo "---
		url: $BLACKSMITH_FORGE_URL
		username: $BLACKSMITH_FORGE_USERNAME
		password: $BLACKSMITH_FORGE_PASSWORD" > ~/.puppetforge.yml
		repo_temp=$(mktemp -d)
		cd "$repo_temp"
		git clone https://$GITHUB_SECRET_TOKEK@github.com/$TRAVIS_REPO_SLUG.git "$repo_temp"
		rake module:release
	fi
fi
