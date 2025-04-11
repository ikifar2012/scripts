#!/bin/bash
# ALL THIS CODE IS LLM GENERATED AND BEING TESTED DO NOT USE YET
#V2
# Prompt for the GitHub username
read -p "Enter the GitHub username: " GITHUB_USER

# Validate if the username is provided
if [ -z "$GITHUB_USER" ]; then
  echo "GitHub username is required. Exiting..."
  exit 1
fi

GITHUB_API_URL="https://api.github.com/users/$GITHUB_USER/keys"

# Get the current user's home .ssh directory
USER=$(whoami)
USER_SSH_DIR="$HOME/.ssh"

# Ensure the .ssh directory exists
if [ ! -d "$USER_SSH_DIR" ]; then
  echo "Directory $USER_SSH_DIR does not exist. Creating it..."
  mkdir -p "$USER_SSH_DIR"
  chown "$USER":"$USER" "$USER_SSH_DIR"
  chmod 700 "$USER_SSH_DIR"
fi

# Set the path for the authorized_keys file
AUTHORIZED_KEYS_FILE="$USER_SSH_DIR/authorized_keys"

# Ensure authorized_keys exists and is owned by the user
if [ ! -f "$AUTHORIZED_KEYS_FILE" ]; then
  echo "File $AUTHORIZED_KEYS_FILE does not exist. Creating it..."
  touch "$AUTHORIZED_KEYS_FILE"
  chown "$USER":"$USER" "$AUTHORIZED_KEYS_FILE"
  chmod 600 "$AUTHORIZED_KEYS_FILE"
fi

# Fetch the SSH keys from GitHub
echo "Fetching SSH keys from GitHub for $GITHUB_USER..."
JSON_KEYS=$(curl -s "$GITHUB_API_URL")

# Check if valid JSON was returned and if there are any keys
KEY_COUNT=$(echo "$JSON_KEYS" | jq '. | length')
if [ "$KEY_COUNT" -eq 0 ]; then
  echo "No SSH keys found for GitHub user $GITHUB_USER. Exiting..."
  exit 1
fi

# List SSH keys with their comments and assign them to an array
declare -a keys_array
echo "Select an SSH key to add to your authorized_keys:"
for (( i=0; i<KEY_COUNT; i++ )); do
  key=$(echo "$JSON_KEYS" | jq -r ".[$i].key")
  comment=$(echo "$JSON_KEYS" | jq -r ".[$i].title")
  echo "$((i+1)). ${comment:-NoTitle} - $key"
  keys_array[$i]="$key"
done

# Ask the user to pick a key
echo "Enter the number of the key you want to add:"
read -p "Choice: " choice

# Validate input: check if choice is a number within valid range
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#keys_array[@]}" ]; then
  echo "Invalid choice. Exiting..."
  exit 1
fi

# Get the selected SSH key (adjust for 0-indexed array)
SELECTED_KEY="${keys_array[$choice-1]}"

# Append the selected SSH key to the authorized_keys file if it's not already present
if grep -qF "$SELECTED_KEY" "$AUTHORIZED_KEYS_FILE"; then
  echo "The selected SSH key is already in the authorized_keys file."
else
  echo "$SELECTED_KEY" >> "$AUTHORIZED_KEYS_FILE"
  echo "SSH key has been successfully added to $USER's authorized_keys."
fi

# Set appropriate permissions
chown "$USER":"$USER" "$AUTHORIZED_KEYS_FILE"
chmod 600 "$AUTHORIZED_KEYS_FILE"