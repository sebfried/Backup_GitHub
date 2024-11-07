# GitHub Backup (macOS)

A script to backup all your GitHub repositories, including those from your personal account and organizations, into a local directory on macOS.

## Setup Instructions

Follow these steps to set up your macOS environment and run the backup script.

### 1. Install Homebrew

Homebrew is a package manager for macOS that simplifies the installation of software.

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow any on-screen instructions to add Homebrew to your PATH.

### 2. Install Git, Git LFS, and GitHub CLI

Use Homebrew to install the necessary tools:

```bash
# Install Git and Git LFS
brew install git git-lfs

# Install jq to hande JSON responses
brew install jq

# Install GitHub CLI
brew install gh

# Initialize Git LFS
git lfs install
```

### 3. Configure Git

Set up your Git user information:

```bash
# Configure your Git username
git config --global user.name "Your Name"

# Configure your Git email
git config --global user.email "your.email@example.com"
```

### 4. Set Up SSH Keys

Generate an SSH key with a custom name and add it to your GitHub account. The keys will be stored in the `.ssh` directory in your home folder.

```bash
# Generate a new SSH key with a custom name
ssh-keygen -t ed25519 -C "your.email@example.com" -f ~/.ssh/github_ed25519

# Start the SSH agent
eval "$(ssh-agent -s)"

# Add your SSH key to the agent
ssh-add -K ~/.ssh/github_ed25519

# Copy the SSH public key to your clipboard
pbcopy < ~/.ssh/github_ed25519.pub
```

- Go to **GitHub** > **Settings** > **SSH and GPG keys**.
- Click **New SSH key**, give it a title, and paste the key.

### 5. Authenticate GitHub CLI

Log in to your GitHub account:

```bash
# Authenticate with GitHub CLI
gh auth login
```

- Choose **GitHub.com**.
- Select **SSL**.
- Select the key you created.
- Log in with your browser when prompted.

### 6. Downlaod the `github-backup` repository

Download this repository.

Certainly! Here is the updated

README.md

with point 7 added to document the new functionality:

### 7. Additional Configuration (optional)

The backup script allows you to **exclude some of your organizations** and **include additional repositories from GitHub** in the backup process, using a `config.json` file.

#### Edit `config.json`

```json
{
  "exclude_orgs": ["your_organization_1", "your_org_2"],
  "include_repos": ["other_user2/repository1", "other_org3/repository2"]
}
```

### 8. Run the Backup Script

Make the script executable and run it:

```bash
# Make the script executable
chmod +x backup.sh

# Run the backup script
./backup.sh
```

The script will:

- Create directories for your account and each organization.
- Clone repositories if they don't exist locally.
- Fetch and pull updates for existing repositories.

### 9. Automate Backups (optional)

To schedule automatic backups, set up a cron job:

```bash
# Edit the crontab
crontab -e
```

Add the following line to run the script daily at midnight:

```bash
0 0 * * * /FULL_PATH_TO_DIRECTORY/github-backup/backup.sh
```
