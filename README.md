# Backup_GitHub (macOS)

**A guide and script to back up and update all your GitHub repositories, including those from your organizations, in a local directory on your Mac.**

**_Plus: Exclude one or more of your organizations and include repositories from all over GitHub!_**

**Note:** The script uses the active Git user configured in your environment and relies on the GitHub CLI (gh) for efficient updates, authenticated separately using `gh auth login`. The backup is performed with `git clone` to retrieve the full Git history.

## Setup Instructions

Follow these steps to set up your macOS environment and run the backup script.

### 1. Install Homebrew

[Homebrew](https://github.com/Homebrew/brew) is a package manager for macOS that simplifies the installation of software.

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow any on-screen instructions to add Homebrew to your PATH.

### 2. Install Git, Git LFS, jq, and GitHub CLI

Use Homebrew to install the necessary tools:

```bash
# Install Git and Git LFS
brew install git git-lfs

# Install jq to handle JSON responses
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

### 6. Download the `Backup_GitHub` repository

Clone the repository to your local machine:

```bash
# Clone the Backup_GitHub repository
git clone https://github.com/yourusername/Backup_GitHub.git ~/path/to/your/Backup_GitHub
```

Download this repository.

### 7. Additional Configuration

The backup script allows you to **exclude some of your organizations** and **include additional repositories from GitHub** in the backup process, using a `config.json` file.

#### Edit `config.json`

Rename `example.config.json` to `config.json` and update it with your preferences:

```json
{
  "exclude_orgs": ["your_organization_1", "your_org_name_2"],
  "include_repos": ["other_user2/repository1", "other_org3/repository2"]
}
```

You can exclude any organizations you don't want to back up and include any additional repositories from other users or organizations.

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

### 9. Set Up an Alias

To simplify running the backup script, you can set up an alias for it:

```bash
# Add the alias using your current directory path
echo 'alias backup-github="'"$(pwd)/backup.sh"'"' >> ~/.zshrc && source ~/.zshrc
```

Now you can run the backup script from anywhere by simply typing `backup-github` in your terminal.
