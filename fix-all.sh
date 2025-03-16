#!/bin/bash
# Script to add SSH key and connect to remote server

# Create SSH directory if it doesn't exist
echo "Creating SSH directory structure..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the provided SSH key to authorized_keys file
echo "Adding SSH key to authorized_keys..."
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC14imbb9qVKJ5jqnzZcxkUlxhCh2kZtwJRd0wogCaeMJThDP+16RRTTBkRoeie0LNOKjuafCBqzrbcSFnlibhWIV2xclKT87TeSlc+9g/bKxjcjLNmSpV+QncOIeXwHFo+cQqyMEeK04EFFpgDJzg767LyGHvjt4Tp3Ks+w2f0YdEyjBFEPkepiTggwyyLRuV8RZAQYaT8Pf8lGmjaT6gexV+H6vflYjBzNjFFU3EEzwXhYaGmZeZ38ihMj8sWLMm4vzs2YVLvdvCq+2qDmpG2vu4at2YqejMeSNdrMMrnfpxI80sHxuvSfQV9wA0SSCm5ErmEtN8jdPRYTn2cHqGv" >> ~/.ssh/authorized_keys

# Set correct permissions on authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Ask user for remote server details
echo -n "Enter the IP address of the remote server: "
read remote_ip

echo -n "Enter the username for the remote server: "
read remote_user

# Create SSH config entry for easier connection
echo "Setting up SSH config..."
cat >> ~/.ssh/config << EOF
Host remote-server
    HostName $remote_ip
    User $remote_user
    IdentityFile ~/.ssh/id_rsa
EOF

chmod 600 ~/.ssh/config

echo "SSH key has been added and configuration created."
echo "You can now connect to the server by typing: ssh remote-server"
echo "Or with the full command: ssh $remote_user@$remote_ip"
echo ""
echo "Would you like to connect now? (y/n)"
read answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    ssh $remote_user@$remote_ip
else
    echo "You can connect later using: ssh $remote_user@$remote_ip"
fi
