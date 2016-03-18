#!/bin/bash -e
# Based on Chris Down's travis-automerge script (https://github.com/cdown/travis-automerge)

: "${GITHUB_SECRET_TOKEN?}"

export BLACKSMITH_FORGE_URL
export BLACKSMITH_FORGE_USERNAME
export BLACKSMITH_FORGE_PASSWORD


export SHA=$(curl https://api.github.com/repos/$TRAVIS_REPO_SLUG/pulls/$TRAVIS_PULL_REQUEST |jq -r .head.sha)
export MESSAGE="Merged automatically by Travis CI. Full testing details on https://travis-ci.org/$TRAVIS_REPO_SLUG/jobs/$TRAVIS_BUILD_ID"
# I just want to do one merge, so I'm checking I'm running in the right Travis Job (Environment)
if [ "$PUPPET_VERSION" = "~> 4.3.0" ]; then
	if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
	    	printf "This is not a Pull Request, I won't be deploying this. Exiting\\n"
	        exit 0
	fi

	printf "SHA of the Commit is $SHA\n"
	printf "Merging PR# $TRAVIS_PULL_REQUEST with message $MESSAGE\n"
	if [ $SHA != null ] || [ -z $SHA ]; then
		curl -X PUT --data "{\"commit_message\":\"$MESSAGE\",\"sha\":\"$SHA\"}" https://$GITHUB_SECRET_TOKEN@api.github.com/repos/$TRAVIS_REPO_SLUG/pulls/$TRAVIS_PULL_REQUEST/merge > /tmp/PR-result
		MERGE=$(cat /tmp/PR-result | jq -r .merged)
	else
		exit 0
	fi
	printf "Merge status is $MERGE\n"
	if [ $MERGE = true ]; then
		printf "go and deploy to $BLACKSMITH_FORGE_URL on $BLACKSMITH_FORGE_USERNAME's account \n"
		echo -e "---\nurl: $BLACKSMITH_FORGE_URL\nusername: $BLACKSMITH_FORGE_USERNAME\npassword: $BLACKSMITH_FORGE_PASSWORD" > ~/.puppetforge.yml
		if [ -f ~/.puppetforge.yml ]; then
			repo_temp=$(mktemp -d)
			cd "$repo_temp"
			git clone https://$GITHUB_SECRET_TOKEN@github.com/$TRAVIS_REPO_SLUG.git "$repo_temp"
			if [ -f $repo_temp/metadata.json ]; then
				git config --global user.email "blacksmith@corrarello.com"
				git config --global user.name "Travis Blacksmith Automation"
				rake module:bump_commit
				if [ $? -eq 0 ]; then
					rake module:tag
					if [ $? -eq 0 ]; then
						git push origin master --tags
						if [ $? -eq 0 ]; then
							rake module:push
						else
							echo "Wasn't able to push tagged version to Github"
						fi
					else
						echo "Wasn't able to tag module"
					fi
				else
					echo "Wasn't able to bump module version"
				fi
			else
				echo "Module repository wasn't properly cloned"
			fi
		else
			echo "Configuration file doesn't exist"
		fi
	else
		echo "Unable to merge PR: \n"
		cat /tmp/PR-result | jq -r .message
	fi
fi
