#!/bin/bash

##################################################################
# GitHub Backup Script v1.71
##################################################################

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read configuration from config.json in the script directory
CONFIG_FILE="$SCRIPT_DIR/config.json"
LOG_FILE="$SCRIPT_DIR/backup.log"
BACKUP_DIR="$SCRIPT_DIR/backup"

# Initialize empty arrays
EXCLUDE_ORGS=()
INCLUDE_REPOS=()

# Check if config.json exists
if [ -f "$CONFIG_FILE" ]; then
    # Parse excluded organizations and included repositories from config.json
    EXCLUDE_ORGS=($(jq -r '.exclude_orgs[]' "$CONFIG_FILE" 2>/dev/null))
    INCLUDE_REPOS=($(jq -r '.include_repos[]' "$CONFIG_FILE" 2>/dev/null))
else
    echo "No 'config.json' configuration file. Proceeding with default settings."
fi

# Ensure the GitHub CLI (gh) is installed and authenticated
if ! command -v gh &>/dev/null; then
    echo "Error: GitHub CLI (gh) is not installed. Please install it and authenticate." | tee -a "$LOG_FILE"
    exit 1
fi

# Check if gh git_protocol is set to ssh
GIT_PROTOCOL=$(gh config get git_protocol)
if [ "$GIT_PROTOCOL" != "ssh" ]; then
    echo "Error: gh git_protocol is not set to 'ssh'." | tee -a "$LOG_FILE"
    echo "Please set it using: 'gh auth login' or 'gh config set git_protocol ssh'" | tee -a "$LOG_FILE"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    echo "Error: The 'jq' utility is required but not installed." | tee -a "$LOG_FILE"
    echo "Install it using: brew install jq" | tee -a "$LOG_FILE"
    exit 1
fi

# Truncate the backup.log file at the start of the script
: > "$LOG_FILE"

# Create backup directory if it does not exist
mkdir -p "$BACKUP_DIR" || { echo "Error: Failed to create backup directory." | tee -a "$LOG_FILE"; exit 1; }
cd "$BACKUP_DIR" || { echo "Error: Failed to change directory to backup directory." | tee -a "$LOG_FILE"; exit 1; }

# Function to check if an organization is in the exclude list
is_excluded_org() {
    local org="$1"
    for excluded_org in "${EXCLUDE_ORGS[@]}"; do
        if [ "$org" == "$excluded_org" ]; then
            return 0   # True, it is excluded
        fi
    done
    return 1  # False, not excluded
}

# Function to clone or update repositories from a given owner
clone_or_update_repos() {
    OWNER=$1
    echo "Processing repositories for $OWNER..." | tee -a "$SCRIPT_DIR/backup.log"
    mkdir -p "$OWNER" || { echo "Error: Failed to create directory for $OWNER." | tee -a "$SCRIPT_DIR/backup.log"; return; }
    cd "$OWNER" || { echo "Error: Failed to change directory to $OWNER." | tee -a "$SCRIPT_DIR/backup.log"; return; }

    # Initialize a flag to track if any repositories were updated or cloned
    updated_repos=false

    if [ "$OWNER" = "$USER_LOGIN" ]; then
        # Use authenticated user endpoint for personal repos
        gh api "user/repos?per_page=100&visibility=all&affiliation=owner" --paginate --jq '.[] | {name: .name, ssh_url: .ssh_url, pushed_at: .pushed_at, private: .private}' >repos.json
    else
        # Use organization/user endpoint for other repos
        gh api "users/$OWNER/repos?per_page=100&type=all&visibility=all" --paginate --jq '.[] | {name: .name, ssh_url: .ssh_url, pushed_at: .pushed_at, private: .private}' >repos.json
    fi
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch repository list for $OWNER. Check $SCRIPT_DIR/backup.log for details." | tee -a "$SCRIPT_DIR/backup.log"
        cd "$SCRIPT_DIR"
        return
    fi
    
    # echo "API output for $OWNER repositories:" | tee -a "$SCRIPT_DIR/backup.log"
    # cat repos.json | tee -a "$SCRIPT_DIR/backup.log"

    jq -c '.' repos.json | while read -r repo; do
        REPO_NAME=$(echo "$repo" | jq -r '.name')
        REPO_URL=$(echo "$repo" | jq -r '.ssh_url')
        LAST_PUSH_DATE=$(echo "$repo" | jq -r '.pushed_at')

        if [ -d "$REPO_NAME/.git" ]; then
            cd "$REPO_NAME" || { echo "Error: Failed to access $REPO_NAME." | tee -a "$SCRIPT_DIR/backup.log"; continue; }
            LOCAL_UPDATED=$(date -u -r .git 2>/dev/null +"%Y-%m-%dT%H:%M:%SZ" || echo "1970-01-01T00:00:00Z")
            # Convert both dates to UTC for accurate comparison
            LAST_PUSH_DATE_UTC=$(date -u -d "$LAST_PUSH_DATE" +"%Y-%m-%dT%H:%M:%SZ")
            LOCAL_UPDATED_UTC=$(date -u -d "$LOCAL_UPDATED" +"%Y-%m-%dT%H:%M:%SZ")

            # echo "Remote updated: $LAST_PUSH_DATE_UTC, Local updated: $LOCAL_UPDATED_UTC" | tee -a "$SCRIPT_DIR/backup.log"

            # Update if the remote is newer than local
            if [ "$LAST_PUSH_DATE_UTC" \> "$LOCAL_UPDATED_UTC" ]; then
                echo "Updating $REPO_NAME..." | tee -a "$SCRIPT_DIR/backup.log"
                git pull >> "$SCRIPT_DIR/backup.log" 2>&1
                if [ $? -ne 0 ]; then
                    echo "Error: Failed to update $REPO_NAME." | tee -a "$SCRIPT_DIR/backup.log"
                else
                    updated_repos=true
                fi
            else
                echo "$REPO_NAME is up to date." | tee -a "$SCRIPT_DIR/backup.log"
            fi
            cd ..
        else
            echo "Cloning $REPO_NAME..." | tee -a "$SCRIPT_DIR/backup.log"
            git clone "$REPO_URL" "$REPO_NAME" >> "$SCRIPT_DIR/backup.log" 2>&1
            if [ $? -ne 0 ]; then
                echo "Error: Failed to clone $REPO_NAME." | tee -a "$SCRIPT_DIR/backup.log"
            else
                updated_repos=true
            fi
        fi
    done

    # Clean up
    rm repos.json
    cd ..

    # Check if any repositories were updated or cloned
    if [ "$updated_repos" = false ]; then
        echo "All repositories for $OWNER are up to date." | tee -a "$SCRIPT_DIR/backup.log"
    fi
}

# Get the authenticated user's login
USER_LOGIN=$(gh api user --jq '.login' 2>/dev/null)
if [ -z "$USER_LOGIN" ]; then
    echo "Error: Failed to get authenticated user login." | tee -a "$SCRIPT_DIR/backup.log"
    cd "$SCRIPT_DIR"
    exit 1
fi
clone_or_update_repos "$USER_LOGIN"

# Get list of organizations the user belongs to
ORG_LOGINS=$(gh api user/orgs --jq '.[].login' 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch organizations for user." | tee -a "$SCRIPT_DIR/backup.log"
fi

# Clone or update repositories for each organization
for ORG_LOGIN in $ORG_LOGINS; do
    if is_excluded_org "$ORG_LOGIN"; then
        echo "Skipping excluded organization $ORG_LOGIN" | tee -a "$SCRIPT_DIR/backup.log"
        continue
    fi
    clone_or_update_repos "$ORG_LOGIN"
done

# Clone or update additional repositories
for REPO_FULLNAME in "${INCLUDE_REPOS[@]}"; do
    OWNER=$(dirname "$REPO_FULLNAME")
    REPO_NAME=$(basename "$REPO_FULLNAME")
    echo "Processing additional repository $REPO_FULLNAME..." | tee -a "$SCRIPT_DIR/backup.log"
    mkdir -p "$OWNER" || { echo "Error: Failed to create directory for $OWNER." | tee -a "$SCRIPT_DIR/backup.log"; continue; }
    cd "$OWNER" || { echo "Error: Failed to change directory to $OWNER." | tee -a "$SCRIPT_DIR/backup.log"; continue; }

    if [ -d "$REPO_NAME/.git" ]; then
        cd "$REPO_NAME" || { echo "Error: Failed to access $REPO_NAME." | tee -a "$SCRIPT_DIR/backup.log"; cd "$SCRIPT_DIR"; continue; }
        echo "Updating $REPO_NAME..." | tee -a "$SCRIPT_DIR/backup.log"
        git pull >> "$SCRIPT_DIR/backup.log" 2>&1
        if [ $? -ne 0 ]; then
            echo "Error: Failed to update $REPO_NAME." | tee -a "$SCRIPT_DIR/backup.log"
        fi
        cd ..
    else
        echo "Cloning $REPO_FULLNAME..." | tee -a "$SCRIPT_DIR/backup.log"
        git clone "git@github.com:$REPO_FULLNAME.git" "$REPO_NAME" >> "$SCRIPT_DIR/backup.log" 2>&1
        if [ $? -ne 0 ]; then
            echo "Error: Failed to clone $REPO_FULLNAME." | tee -a "$SCRIPT_DIR/backup.log"
        fi
    fi
    cd "$BACKUP_DIR" || { echo "Error: Failed to return to backup directory." | tee -a "$SCRIPT_DIR/backup.log"; cd "$SCRIPT_DIR"; }
done

echo "Backup process completed at $(date)." | tee -a "$SCRIPT_DIR/backup.log"
echo "All repositories have been cloned or updated in $(pwd)." | tee -a "$SCRIPT_DIR/backup.log"

# Return to the starting directory
cd "$SCRIPT_DIR"