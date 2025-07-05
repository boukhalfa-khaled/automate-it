## git-remote-init.sh

This is a simple Bash script that automates the process of creating a new GitHub repository and connecting it to your local project.
- Creates a **remote GitHub repository** using the GitHub API
- Optionally makes the repository **public** or **private**
- Initializes a local Git repository 
- Adds remote origin and pushes the initial commit

---

## Requirements

- `git` installed on your system and ssh authentication
-  A GitHub account and api token

---

```bash
./create_repo.sh <repo-name> [--public]

