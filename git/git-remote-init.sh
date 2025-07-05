#!/bin/sh

# GitHub Repository Creation Script
# Author: boukhalfa-khaled-islam
# Description: Creates a new GitHub repository and  connect it to local repo
#   - Private by default, public with --public flag
#   - Simple usage: ./create_repo.sh <repository-name> [--public]
# Usage examples:
#   ./create_repo.sh my-project          # Creates private repo
#   ./create_repo.sh my-project --public # Creates public repo

# ========================================
#              Configuration             =    
# ========================================

# Your GitHub username and api token or  use environment variable for token for security
GITHUB_USER="boukhalfa-khaled"
GITHUB_TOKEN="xxxx_xxxx"
# GitHub API endpoint for creating repositories
API_URL="https://api.github.com/user/repos"

# Input Validation                  
if [ $# -eq 0 ]; then
    echo "ERROR: Repository name is required" >&2
    echo "Usage: $0 <repository-name> [--public]" >&2
    exit 1
fi
REPO_NAME="$1"
if [ "$2" = "--public" ]; then
    VISIBILITY="public"
    PRIVATE="false"
else
    VISIBILITY="private"
    PRIVATE="true"
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "ERROR: GitHub token not found!" >&2
    echo "Please set your token with:" >&2
    echo "   export GITHUB_TOKEN=\"your_github_token\"" >&2
    exit 1
fi
if [ -d "$REPO_NAME" ]; then
    echo "ERROR: Directory '$REPO_NAME' already exists" >&2
    exit 1
fi
#          remote Repository creation        
echo "Creating $VISIBILITY remote repository '$REPO_NAME' on GitHub..."
response=$(
    curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -X POST "$API_URL" \
    -d '{
        "name": "'"$REPO_NAME"'",
        "private": '"$PRIVATE"'
    }'
)
case $response in
    201)
        echo "✅ Successfully created $VISIBILITY repository"
        ;;
    422)
        echo "ℹ️ Repository '$REPO_NAME' already exists. Continuing..."
        ;;
    *)
        echo "⛔ Failed to create repository (HTTP $response)" >&2
        exit 1
        ;;
esac

echo "Creating local directory and initializing Git repository..."
mkdir "$REPO_NAME"
cd "$REPO_NAME" 
# because github default branch is main
git init -b main
echo "# $REPO_NAME" > README.md
echo "Repository created by script" >> README.md
git add README.md
git commit -m "Initial commit"
echo "✅ Local repository initialized"

echo "Connecting to GitHub..."
REMOTE_URL="git@github.com:$GITHUB_USER/$REPO_NAME.git"
git remote add origin "$REMOTE_URL"
echo "Pushing code to GitHub..."
if git push -u origin main; then
    echo "✅ Successfully pushed to 'main' branch"
else
    echo "⛔ Failed to push to remote repository" >&2
    echo "Possible solutions:" >&2
    echo "1. Ensure your SSH key is added to ssh-agent: ssh-add ~/.ssh/id_rsa" >&2
    echo "2. Verify your SSH key is added to GitHub: https://github.com/settings/keys" >&2
    echo "3. Test your SSH connection: ssh -T git@github.com" >&2
    exit 1
fi
REPO_URL="https://github.com/$GITHUB_USER/$REPO_NAME"
echo ""
echo "------------------------------------------------"
echo "🎉 Your new $VISIBILITY repository is ready!"
echo ""
echo "Local path: $(pwd)"
echo ""
echo "You can visit your repository at:"
echo "  $REPO_URL"
echo ""
echo "To start hacking:"
echo "  cd $REPO_NAME"
echo "------------------------------------------------"
