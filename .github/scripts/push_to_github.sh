#!/bin/bash

#!/bin/bash
set -e

# Usage: ./github_release.sh <version>
# Example: ./github_release.sh 6.6.6

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 VERSION IS_BETA RC_BRANCH IOS_AFSDK ANDROID_AFSDK"
  exit 1
fi

IS_BETA=$1
RC_BRANCH=$2
IOS_AFSDK=$3
ANDROID_AFSDK=$4

# Extract the version from RC_BRANCH.
# Expected RC_BRANCH format: releases/[...]/[...]/<version>_rc<number>
if [[ $RC_BRANCH =~ .*/([0-9]+\.[0-9]+\.[0-9]+)_rc[0-9]+ ]]; then
    NEW_VERSION="${BASH_REMATCH[1]}"
else
    echo "$RC_BRANCH" 
    echo "Error: RC_BRANCH does not match expected format."
    exit 1
fi

if [[ "$IS_BETA" != "yes" && "$IS_BETA" != "no" ]]; then
  echo "Error: IS_BETA must be either 'yes' or 'no'"
  exit 1
fi

# Function: Checkout master branch and pull latest changes.
checkout_branch() {
  local branch=$1
  echo "==> Checking out $branch branch and pulling latest changes..."
  git checkout "$branch"
  git pull origin "$branch"
}

setGitHubToken(){
  echo "==> Setting GitHub token..."
  git remote set-url origin https://$CI_GITHUB_TOKEN@github.com/AppsFlyerSDK/appsflyer-flutter-plugin.git
}

# Function: Run Flutter tests.
run_tests() {
  echo "==> Running Flutter tests..."
  flutter test
}

# Function: Run a dry run of the pub publish command.
dry_run_publish() {
  echo "==> Running flutter pub publish --dry-run..."
  flutter pub publish --dry-run
}

# Function: Commit changes if there are any.
commit_changes() {
  echo "==> Committing changes..."
  git add .
  # If there are no changes, this will fail, so we ignore the error.
  git commit -m "Release version $NEW_VERSION" || echo "No changes to commit."
}

# Function: Create a Git tag for the new release.
create_tag() {
  echo "==> Creating Git tag v$NEW_VERSION..."
  git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"
}

create_release() {
  echo "==> Creating GitHub release for tag v$NEW_VERSION..."

  API_JSON=$(jq -n \
    --arg tag "v$NEW_VERSION" \
    --arg name "Release v$NEW_VERSION" \
    --arg body "Automated release of version $NEW_VERSION" \
    '{ tag_name: $tag, name: $name, body: $body, draft: false, prerelease: false }')

  curl -s -X POST "https://api.github.com/repos/AppsFlyerSDK/appsflyer-flutter-plugin/releases" \
    -H "Authorization: token $CI_GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$API_JSON"
}

# Function: Push changes and tags to the remote repository.
push_changes() {
  local branch=$1
  echo "==> Pushing changes and tags to GitHub..."
  git push origin "$branch"
}

# Function: Publish the Flutter package to pub.dev.
publish_package() {
  echo "==> Publishing package to pub.dev..."
  flutter pub publish
}

# Main Release Function: Run all steps in order.
QA_release_flutter_sdk() {
  echo "==> Starting release process to QA..."
  checkout_branch "$RC_BRANCH"
  setGitHubToken
  ./.github/scripts/bump_sdk.sh "$NEW_VERSION" "$IOS_AFSDK" "$ANDROID_AFSDK"
  commit_changes
  push_changes "$RC_BRANCH"
}

# Prod_release_flutter_sdk() {
#   echo "==> Starting release process to Production..."
#   checkout_branch "$master"
#   setGitHubToken
#   create_tag
#   create_release
#   dry_run_publish
#   publish_package
# }

# Execute the release process.

if [[ "IS_BETA" = "yes" ]]: then
    QA_release_flutter_sdk
fi
