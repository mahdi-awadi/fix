#!/bin/bash
# Fix-All-Issues.sh - Script to repair AlmaLinux system

# Fix network configuration
echo "Fixing network configuration..."
cat > /etc/sysconfig/network-scripts/ifcfg-enp3s0 << 'EOF'
DEVICE=enp3s0
BOOTPROTO=static
IPADDR=107.155.122.225
NETMASK=255.255.255.0
GATEWAY=107.155.122.1
DNS1=8.8.8.8
DNS2=1.1.1.1
ONBOOT=yes
EOF

# Set up DNS permanently
echo "Setting up DNS..."
cat > /etc/resolv.conf << 'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Make resolv.conf immutable to prevent changes
chattr +i /etc/resolv.conf

# Fix PAM authentication
echo "Fixing PAM authentication..."
cat > /etc/pam.d/system-auth << 'EOF'
auth        sufficient    pam_rootok.so
auth        required      pam_unix.so nullok try_first_pass
auth        required      pam_deny.so

account     required      pam_unix.so

password    required      pam_unix.so sha512 shadow nullok try_first_pass use_authtok

session     required      pam_unix.so
session     required      pam_limits.so
EOF

# Fix login services
echo "Fixing login services..."
for service in login sshd gdm-password; do
  cat > /etc/pam.d/$service << 'EOF'
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
EOF
done

# Allow root login in GDM
echo "Allowing root login in GDM..."
mkdir -p /etc/gdm
cat > /etc/gdm/custom.conf << 'EOF'
[daemon]
AutomaticLoginEnable=false
TimedLoginEnable=false

[security]
AllowRoot=true
EOF

# Set SELinux to permissive mode
echo "Setting SELinux to permissive mode..."
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# Reset systemd to default state
echo "Resetting systemd services..."
systemctl preset-all

# Restart network service
echo "Restarting network service..."
systemctl restart network
systemctl enable network

# Enable and restart display manager
echo "Setting up display services..."
systemctl enable gdm
systemctl restart gdm

echo "All issues fixed! The system should now have working network, PAM authentication, and login services."
echo "You should be able to log in as root through VNC without timeout issues."
