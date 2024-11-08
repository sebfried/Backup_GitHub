# Backup_GitHub (macOS)

**A guide and script to back up and update all your GitHub repositories, including those from your organizations, in a local directory on your Mac.**

**_Plus: Exclude one or more of your organizations and include repositories from all over GitHub!_**

**Note:** The script uses the active Git user configured in your environment and relies on the GitHub CLI (`gh`) for efficient updates. Authentication is managed separately via `gh auth login`. The backup retrieves the full Git history with `git clone`.

---

## Setup Instructions

Follow these steps to set up your macOS environment and run the backup script.

### 1. Install Homebrew

[Homebrew](https://github.com/Homebrew/brew) is a package manager for macOS that simplifies software installation.

#### Install Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow any on-screen instructions to add Homebrew to your PATH.

---

### 2. Install Git, Git LFS, jq, and GitHub CLI

Use Homebrew to install the necessary tools:

#### Install Git, Git LFS, GitHub CLI, and jq:

```bash
brew install git git-lfs gh jq
```

**Note:** [jq](https://jqlang.github.io/jq/) is a lightweight and flexible command-line JSON processor. The script uses it to process GitHub metadata and the `config.json` file.

**Initialize Git LFS:**

```bash
git lfs install
```

---

### 3. Configure Git

Set up your Git user information with your GitHub credentials:

#### Configure your Git username:

```bash
git config --global user.name "Your GitHub username"
```

#### Configure your Git email:

```bash
git config --global user.email "your.github.email@example.com"
```

---

### 4. Set Up SSH Keys

Generate an SSH key with a custom name and add it to your GitHub account. The keys will be stored in the `.ssh` directory in your home folder.

#### Generate a new SSH key with a custom name:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/github_ed25519 -C "your.github.email@example.com"
```

#### Start the SSH agent:

```bash
eval "$(ssh-agent -s)"
```

#### Add your SSH key to the agent:

```bash
ssh-add -K ~/.ssh/github_ed25519
```

#### Copy the SSH public key to your clipboard:

```bash
pbcopy < ~/.ssh/github_ed25519.pub
```

#### Add the key on GitHub:

1. Go to **GitHub** > **Settings** > **SSH and GPG keys**.
2. Click **New SSH key**, give it a title, and paste the key.

---

### 5. Authenticate GitHub CLI

#### Log in to your GitHub account:

```bash
gh auth login
```

- Choose **GitHub.com**.
- Select **SSH**.
- Use the key you created.
- Log in with your browser when prompted.

---

### 6. Get the `Backup_GitHub` Repository

#### Clone this repository:

```bash
git clone https://github.com/sebfried/Backup_GitHub.git && cd Backup_GitHub
```

---

### 7. Additional Configuration

The backup script allows you to **exclude specific organizations** and **include additional repositories from GitHub** in the backup process, using a `config.json` file.

#### Edit `config.json`

Rename `example.config.json` to `config.json` and update it with your preferences:

```json
{
  "exclude_orgs": ["your_organization_1", "your_org_name_2"],
  "include_repos": ["other_user2/repository1", "other_org3/repository2"]
}
```

You can exclude any organizations you don't want to back up and include any additional repositories from other users or organizations.

---

### 8. Run the Backup Script

Make the script executable and run it:

#### Make the script executable:

```bash
chmod +x backup.sh
```

#### Run the backup script:

```bash
./backup.sh
```

The script will:

- Create directories for your account and each organization.
- Clone repositories if they don't exist locally.
- Fetch and pull updates for existing repositories.

---

### 9. Set Up an Alias

To simplify running the backup script, you can set up an alias for it.

Add the alias using your current directory path:

```bash
echo 'alias backup-github="'"$(pwd)/backup.sh"'"' >> ~/.zshrc && source ~/.zshrc
```

Now you can run the backup script from anywhere by simply typing `backup-github` in your terminal.
