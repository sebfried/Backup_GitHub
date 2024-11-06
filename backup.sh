#!/bin/bash

# Ensure the GitHub CLI (gh) is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it and authenticate."
    exit 1
fi

# Navigate to the directory of the script
cd "$(dirname "$0")" || exit

# Create a backup directory if it does not exist
BACKUP_DIR="backup"
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit

# Function to clone or update repositories from a given owner
clone_or_update_repos() {
    OWNER=$1
    echo "Processing repositories for $OWNER..."
    mkdir -p "$OWNER"
    cd "$OWNER" || exit

    gh repo list "$OWNER" --limit 1000 --json name,nameWithOwner \
    --template '{{range .}}{{.name}} {{.nameWithOwner}}{{"\n"}}{{end}}' | while read -r REPO_NAME REPO_FULLNAME; do
        if [ -d "$REPO_NAME" ]; then
            echo "Updating $REPO_NAME..."
            cd "$REPO_NAME" || continue
            git fetch --all
            git pull --all
            cd ..
        else
            echo "Cloning $REPO_FULLNAME..."
            gh repo clone "$REPO_FULLNAME" "$REPO_NAME"
        fi
    done

    cd ..
}

# Get the authenticated user's login
USER_LOGIN=$(gh api user --jq '.login')
clone_or_update_repos "$USER_LOGIN"

# Get list of organizations the user belongs to
ORG_LOGINS=$(gh api user/orgs --jq '.[].login')

# Clone or update repositories for each organization
for ORG_LOGIN in $ORG_LOGINS; do
    clone_or_update_repos "$ORG_LOGIN"
done

echo "All repositories have been cloned or updated in $(pwd)."