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
	fi
	# Since Travis does a partial checkout, we need to get the whole thing
	#repo_temp=$(mktemp -d)
	#git clone "https://github.com/$GITHUB_REPO" "$repo_temp"

	# shellcheck disable=SC2164
	#cd "$repo_temp"

	#printf 'Checking out %s\n' "$BRANCH_TO_MERGE_INTO" >&2
	#git checkout "$BRANCH_TO_MERGE_INTO"

	#printf 'Merging %s\n' "$TRAVIS_COMMIT" >&2
	#git merge --ff-only "$TRAVIS_COMMIT"

	#printf 'Pushing to %s\n' "$GITHUB_REPO" >&2

	#push_uri="https://$GITHUB_SECRET_TOKEN@github.com/$GITHUB_REPO"

	# Redirect to /dev/null to avoid secret leakage
	#git push "$push_uri" "$BRANCH_TO_MERGE_INTO" >/dev/null 2>&1
	#git push "$push_uri" :"$TRAVIS_BRANCH" >/dev/null 2>&1
	
	#if [ $PUPPET_GEM_VERSION = "~> 4.3" ] && [ $DEPLOY = "true" ]; then
	#	printf "Pushing module to the Puppet Forge\n"
	#	rake module:release
	#fi
fi
