#!/bin/bash
# Comprehensive System Repair Script
# Fixes login services, PAM authentication, network services and more

echo "Starting system repair..."

# 1. Fix network configuration
echo "Configuring network..."
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

# Set up DNS configuration
cat > /etc/resolv.conf << 'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# 2. Fix PAM authentication
echo "Repairing PAM configuration..."
# Fix system-auth PAM configuration
cat > /etc/pam.d/system-auth << 'EOF'
auth        required      pam_env.so
auth        sufficient    pam_unix.so nullok try_first_pass
auth        sufficient    pam_rootok.so
auth        required      pam_deny.so

account     required      pam_unix.so
account     sufficient    pam_localuser.so
account     required      pam_permit.so

password    requisite     pam_pwquality.so try_first_pass local_users_only
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session    optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so
EOF

# Fix login PAM configuration
cat > /etc/pam.d/login << 'EOF'
auth       required     pam_securetty.so
auth       include      system-auth
account    required     pam_nologin.so
account    include      system-auth
password   include      system-auth
session    required     pam_selinux.so open
session    required     pam_loginuid.so
session    optional     pam_keyinit.so force revoke
session    include      system-auth
-session   optional     pam_systemd.so
session    required     pam_selinux.so close
EOF

# Fix sshd PAM configuration
cat > /etc/pam.d/sshd << 'EOF'
auth       required     pam_sepermit.so
auth       include      system-auth
account    required     pam_nologin.so
account    include      system-auth
password   include      system-auth
session    required     pam_selinux.so open
session    required     pam_loginuid.so
session    optional     pam_keyinit.so force revoke
session    include      system-auth
-session   optional     pam_systemd.so
session    required     pam_selinux.so close
EOF

# 3. Fix GDM for root login
echo "Configuring display manager..."
mkdir -p /etc/gdm
cat > /etc/gdm/custom.conf << 'EOF'
[daemon]
AutomaticLoginEnable=false
TimedLoginEnable=false

[security]
AllowRoot=true
EOF

# Fix gdm-password PAM config
cat > /etc/pam.d/gdm-password << 'EOF'
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
EOF

# 4. Set SELinux to permissive mode
echo "Setting SELinux to permissive mode..."
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# 5. Fix file permissions for authentication files
echo "Fixing file permissions..."
chmod 0600 /etc/shadow
chmod 0644 /etc/passwd
chmod 0644 /etc/group
chmod 750 /root
chown -R root:root /root

# 6. Fix systemd services
echo "Repairing systemd services..."
systemctl daemon-reexec
systemctl restart systemd-logind
systemctl enable systemd-logind

# 7. Fix network services
echo "Repairing network services..."
systemctl restart NetworkManager
systemctl enable NetworkManager

# 8. Restart key services
echo "Restarting critical services..."
systemctl try-restart systemd-journald
systemctl try-restart dbus

# 9. Check for and reinstall key authentication packages
echo "Checking authentication packages..."
if command -v dnf &> /dev/null; then
    dnf reinstall -y pam shadow-utils util-linux-user
else
    yum reinstall -y pam shadow-utils util-linux-user
fi

# 10. Set proper hostname if it's missing
hostname=$(hostname)
if [ -z "$hostname" ] || [ "$hostname" = "localhost" ]; then
    echo "Setting hostname..."
    hostnamectl set-hostname ns2.cpahost.com
fi

echo "System repair completed. Please reboot the system with 'reboot' command."
echo "After reboot, you should be able to log in normally."
