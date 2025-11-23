---
id: linux-02-directory-hierarchy
topic: linux
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [linux-basics]
related_topics: ['unix', 'shell', 'bash']
embedding_keywords: [linux]
last_reviewed: 2025-11-13
---

# Linux Binary Directory Hierarchy

**Comprehensive Guide to `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`, `/usr/local/bin`, and `/opt/*/bin`**

---

## Table of Contents

1. [Overview](#overview)
2. [The Filesystem Hierarchy Standard (FHS)](#the-filesystem-hierarchy-standard-fhs)
3. [/bin - Essential User Commands](#bin---essential-user-commands)
4. [/sbin - Essential System Commands](#sbin---essential-system-commands)
5. [/usr/bin - Primary User Applications](#usrbin---primary-user-applications)
6. [/usr/sbin - Non-Essential System Administration](#usrsbin---non-essential-system-administration)
7. [/usr/local/bin - Locally-Compiled User Programs](#usrlocalbin---locally-compiled-user-programs)
8. [/usr/local/sbin - Local System Administration](#usrlocalsbin---local-system-administration)
9. [/opt/*/bin - Third-Party Software Packages](#optbin---third-party-software-packages)
10. [The UsrMerge: Modern Simplification](#the-usrmerge-modern-simplification)
11. [Decision Tree: Where Should I Install?](#decision-tree-where-should-i-install)
12. [Comparison Table](#comparison-table)
13. [Best Practices](#best-practices)
14. [Common Mistakes](#common-mistakes)

---

## Overview

Linux organizes executable binaries across multiple directories, each with distinct purposes defined by the **Filesystem Hierarchy Standard (FHS)**. Understanding these distinctions is critical for:

- **System administrators**: Proper installation and package management
- **Developers**: Correct deployment locations for custom software
- **Package maintainers**: Compliance with distribution standards
- **Users**: Understanding PATH order and command resolution

### The Core Principle

The hierarchy separates binaries based on:

1. **Essentiality**: Required for boot/recovery vs. optional
2. **Privilege Level**: User-accessible vs. root-only
3. **Management**: Distribution-managed vs. locally-installed
4. **Scope**: System-wide vs. application-specific

---

## The Filesystem Hierarchy Standard (FHS)

**Version**: FHS 3.0 (2015, updated from 2.3)

The FHS defines these binary directories:

| Directory | Purpose | Essential? | Manager |
|-----------|---------|------------|---------|
| `/bin` | Essential user commands | Yes | Distribution |
| `/sbin` | Essential system commands | Yes | Distribution |
| `/usr/bin` | Primary user applications | No | Distribution |
| `/usr/sbin` | Non-essential system binaries | No | Distribution |
| `/usr/local/bin` | Locally-compiled user programs | No | Administrator |
| `/usr/local/sbin` | Local system administration | No | Administrator |
| `/opt/*/bin` | Add-on application packages | No | Vendor/Admin |

### Historical Context

- **Pre-1990s**: All binaries in `/bin` and `/sbin`
- **1990s-2010s**: Separation into `/usr` hierarchy for networked filesystems
- **2010s-Present**: UsrMerge trend consolidating `/bin` → `/usr/bin`

---

## /bin - Essential User Commands

### Purpose

Contains **critical binaries required for**:
- Single-user mode (emergency recovery)
- Booting the system before `/usr` is mounted
- System repair when other filesystems fail
- Basic shell operations

### Characteristics

- **Mount Dependency**: Must work even if `/usr` is not mounted
- **Size**: Typically 10-50 MB
- **Package Management**: Managed by core system packages (e.g., `coreutils`, `bash`)
- **User Access**: All users can execute

### Typical Contents

```bash
# Filesystem Operations
ls, cp, mv, rm, mkdir, rmdir, ln, chmod, chown

# Text Processing
cat, grep, sed, echo, more, less

# Shell
bash, sh, dash

# System Info
ps, uname, date, hostname

# Compression
gzip, gunzip, bzip2, tar

# Networking (Basic)
ping, netstat (on some systems)
```

### Real-World Example

```bash
$ ls -lh /bin | head -20
lrwxrwxrwx 1 root root 7 Jan 15 2024 bin -> usr/bin # Modern UsrMerge system
```

Or on older systems:

```bash
$ ls /bin
bash cat chmod chown cp date dd df dmesg echo false grep gzip
hostname kill ln login ls mkdir mknod more mount mv netstat ping
ps pwd rm rmdir sed sh sleep su sync tar true umount uname
```

### Who Manages It?

- **Distribution Package Manager**: `apt`, `dnf`, `pacman`
- **Core Packages**: `coreutils`, `util-linux`, `bash`, `grep`, `sed`

### When to Use

❌ **NEVER** manually install to `/bin` (distribution-managed)

✅ **Appropriate Use Cases**:
- None for manual installation
- Package managers only

### When NOT to Use

❌ **Incorrect**:
```bash
# DON'T: Manually install custom script
sudo cp my-script.sh /bin/my-script

# DON'T: Install third-party software
sudo cp nodejs /bin/node
```

✅ **Correct**:
```bash
# DO: Use /usr/local/bin for custom scripts
sudo cp my-script.sh /usr/local/bin/my-script

# DO: Let package manager handle /bin
sudo apt install coreutils
```

---

## /sbin - Essential System Commands

### Purpose

Contains **system administration binaries required for**:
- Booting and system initialization (`init`, `fsck`)
- Filesystem operations (`mount`, `mkfs`)
- Network configuration (`ifconfig`, `ip`)
- Hardware management (`lspci`, `hdparm`)

### Characteristics

- **Privilege**: Typically requires root/sudo
- **Essentiality**: Needed for system recovery
- **Mount Dependency**: Must work without `/usr`
- **PATH**: Usually not in normal user's PATH

### Typical Contents

```bash
# System Initialization
init, shutdown, reboot, halt, telinit

# Filesystem Management
fsck, mkfs, mount, umount, fdisk, parted, blkid

# Network Configuration
ifconfig, ip, route, iptables, dhclient

# System Diagnostics
lspci, lsusb, lsmod, dmesg

# User Management
useradd, usermod, userdel, groupadd

# Service Management (older systems)
service, chkconfig
```

### Real-World Example

```bash
$ ls /sbin
agetty blkid blockdev bridge ctrlaltdel debugfs depmod dhclient
dumpe2fs e2fsck e2image e2label e2undo fdisk findfs fsck fsck.ext4
fstrim getty halt hwclock ifconfig init insmod ip iptables kexec
logsave lsmod mke2fs mkfs mkfs.ext4 mkswap modinfo modprobe mount
mount.nfs pivot_root poweroff reboot resize2fs rmmod route runlevel
shutdown sulogin swapoff swapon switch_root sysctl telinit tune2fs
udevadm umount
```

### Who Manages It?

- **Distribution**: System packages (`util-linux`, `e2fsprogs`, `iproute2`)
- **Never**: Manual administrator installation

### When to Use

❌ **NEVER** manually install to `/sbin` (distribution-managed)

### When NOT to Use

❌ **Incorrect**:
```bash
# DON'T: Install custom admin tool
sudo cp my-admin-tool /sbin/my-admin-tool

# DON'T: Install monitoring software
sudo cp nagios-check /sbin/nagios-check
```

✅ **Correct**:
```bash
# DO: Use /usr/local/sbin for custom admin tools
sudo cp my-admin-tool /usr/local/sbin/my-admin-tool

# DO: Use /opt for third-party packages
sudo cp -r nagios /opt/nagios
```

---

## /usr/bin - Primary User Applications

### Purpose

The **primary location for user-accessible executables** including:
- Programming languages and compilers
- Text editors and IDEs
- System utilities (non-essential)
- User applications

### Characteristics

- **Size**: Typically 1-3 GB on modern systems
- **Mount**: Requires `/usr` to be mounted (not needed for boot)
- **Package Management**: Managed by distribution packages
- **Scope**: System-wide applications

### Typical Contents

```bash
# Programming Languages
python3, perl, ruby, node, java, gcc, g++, make

# Editors
vim, nano, emacs, code (VSCode)

# Version Control
git, svn, hg

# File Management
find, locate, which, xargs, diff

# Text Processing
awk, cut, sort, uniq, wc, tr, column

# Compression
zip, unzip, 7z, xz

# System Utilities
top, htop, free, df, du, lsof, strace

# Networking
curl, wget, ssh, scp, rsync, nmap

# Database Clients
mysql, psql, sqlite3

# Container Tools
docker (client), kubectl, podman
```

### Real-World Example

```bash
$ ls /usr/bin | wc -l
2847 # Typical modern Linux system has 2000-4000 binaries here

$ which python3 git docker
/usr/bin/python3
/usr/bin/git
/usr/bin/docker
```

### Who Manages It?

- **Package Manager**: `apt`, `dnf`, `pacman`, `zypper`
- **Packages**: Language packages, developer tools, applications

### When to Use

✅ **Appropriate for Package Managers**:
```bash
# Package managers install here automatically
sudo apt install python3-pip # → /usr/bin/pip3
sudo dnf install nodejs # → /usr/bin/node
```

❌ **NOT for Manual Installation**:
```bash
# DON'T: Manually copy binaries here
sudo cp ~/Downloads/custom-tool /usr/bin/custom-tool
```

### When NOT to Use

❌ **Incorrect**:
```bash
# Installing from source manually
sudo make install # Often defaults to /usr/local, but check!
sudo cp binary /usr/bin/binary # Conflicts with package manager
```

✅ **Correct**:
```bash
# Let package manager handle it
sudo apt install package-name

# For manual installs, use /usr/local/bin
sudo cp binary /usr/local/bin/binary
```

---

## /usr/sbin - Non-Essential System Administration

### Purpose

Contains **system administration commands that are not required for boot/recovery**:
- Service management (systemd, daemons)
- User management tools
- Network services
- System monitoring

### Characteristics

- **Privilege**: Typically requires root
- **Essentiality**: Not needed for emergency boot
- **Package Management**: Distribution-managed
- **PATH**: May or may not be in user's PATH (often added for sudo)

### Typical Contents

```bash
# Service Management
systemctl (systemd), service, update-rc.d

# User/Group Management
adduser, deluser, visudo, chpasswd

# Network Services
apache2, nginx, sshd, named (BIND), postfix

# Package Management
apt-get, dpkg, yum, dnf, zypper

# System Configuration
dpkg-reconfigure, update-alternatives, locale-gen

# Monitoring
atop, iotop, nethogs

# Virtualization
libvirtd, qemu-system-x86_64

# Firewall
ufw, firewalld
```

### Real-World Example

```bash
$ ls /usr/sbin | grep -E '(systemctl|apache2|sshd|useradd)'
apache2
sshd
systemctl
useradd

$ which systemctl
/usr/sbin/systemctl

# On many systems, root's PATH includes /usr/sbin
$ sudo echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### Who Manages It?

- **Distribution**: Service packages, admin tools
- **Never**: Manual installation

### When to Use

✅ **Package Manager Only**:
```bash
sudo apt install apache2 # → /usr/sbin/apache2
sudo dnf install nginx # → /usr/sbin/nginx
```

### When NOT to Use

❌ **Incorrect**:
```bash
# DON'T: Manual daemon installation
sudo cp my-daemon /usr/sbin/my-daemon
```

✅ **Correct**:
```bash
# DO: Build a.deb/.rpm package, or use /usr/local/sbin
sudo cp my-daemon /usr/local/sbin/my-daemon
```

---

## /usr/local/bin - Locally-Compiled User Programs

### Purpose

The **administrator's domain for custom user applications** not managed by the distribution:
- Manually compiled software
- Custom scripts shared system-wide
- Third-party binaries (single-file)
- Organization-specific tools

### Characteristics

- **Package Manager**: **NEVER** touches this directory
- **Management**: System administrator's responsibility
- **Priority**: Appears **before** `/usr/bin` in PATH
- **Scope**: System-wide (all users)

### Typical Contents

```bash
# Custom Scripts
backup-database.sh
deploy-app.py
system-health-check

# Manually Installed Software
node (from nodejs.org tarball)
python3.12 (compiled from source)
custom-monitoring-agent

# Third-Party Single Binaries
terraform
kubectl (manual download)
helm
```

### Real-World Example

```bash
$ echo $PATH
/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
# ^^^^^^^^^^^^^^ Takes precedence over /usr/bin

$ ls /usr/local/bin
backup-db.sh node npm python3.11 terraform kubectl

# Custom Python installation
$ which python3.11
/usr/local/bin/python3.11

$ which python3
/usr/bin/python3 # System Python
```

### Who Manages It?

- **System Administrator**: Manual installation, organization scripts
- **Build Systems**: `make install` (default prefix=/usr/local)
- **NOT**: Package managers (apt/dnf/pacman)

### When to Use

✅ **Appropriate Use Cases**:

```bash
# ✅ Installing from source
./configure --prefix=/usr/local
make
sudo make install # Installs to /usr/local/bin

# ✅ Custom organization script
sudo cp backup-tool.sh /usr/local/bin/backup-tool
sudo chmod +x /usr/local/bin/backup-tool

# ✅ Single-binary third-party tool
sudo curl -o /usr/local/bin/terraform https://releases.hashicorp.com/.../terraform
sudo chmod +x /usr/local/bin/terraform

# ✅ Manual Python/Node installation
tar -xzf Python-3.12.0.tgz
cd Python-3.12.0
./configure --prefix=/usr/local
make && sudo make install # → /usr/local/bin/python3.12
```

### When NOT to Use

❌ **Incorrect**:

```bash
# DON'T: Install package-managed software here
sudo apt install nodejs # Already goes to /usr/bin
sudo cp /usr/bin/node /usr/local/bin/node # Creates confusion

# DON'T: Install large multi-file applications
sudo cp -r my-complex-app/ /usr/local/bin/ # Wrong! Use /opt
```

✅ **Correct Alternatives**:

```bash
# For package-managed software
sudo apt install nodejs # → /usr/bin/node

# For complex applications
sudo cp -r my-complex-app /opt/my-app
sudo ln -s /opt/my-app/bin/my-app /usr/local/bin/my-app
```

---

## /usr/local/sbin - Local System Administration

### Purpose

**Administrator's domain for custom system administration tools** requiring root privileges:
- Custom system maintenance scripts
- Local daemon/service binaries
- Organization-specific admin tools
- Compiled system utilities

### Characteristics

- **Privilege**: Root-only operations
- **Package Manager**: Never managed by distribution
- **PATH**: Included in root's PATH, often not in user's PATH
- **Scope**: System-wide administrative tasks

### Typical Contents

```bash
# Custom Admin Scripts
cleanup-logs.sh
rotate-backups.sh
monitor-disk-usage.py

# Locally Compiled System Tools
custom-firewall-manager
database-backup-daemon

# Organization Infrastructure
deploy-config-update
restart-all-services
```

### Real-World Example

```bash
# Root's PATH includes /usr/local/sbin
$ sudo echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# ^^^^^^^^^^^^^^^ First in PATH for root

$ sudo ls /usr/local/sbin
cleanup-old-logs custom-backup firewall-update service-monitor

# Regular user typically doesn't have it in PATH
$ echo $PATH
/usr/local/bin:/usr/bin:/bin:/usr/games
# No /usr/local/sbin
```

### Who Manages It?

- **System Administrator**: Manual installation
- **Configuration Management**: Ansible, Puppet, Chef, Salt
- **NOT**: Distribution package manager

### When to Use

✅ **Appropriate Use Cases**:

```bash
# ✅ Custom system maintenance script
sudo cp cleanup-logs.sh /usr/local/sbin/cleanup-logs
sudo chmod 700 /usr/local/sbin/cleanup-logs # Root-only

# ✅ Compiled admin tool
./configure --prefix=/usr/local
make
sudo make install # Installs sbin tools to /usr/local/sbin

# ✅ Organization-specific daemon
sudo cp monitoring-agent /usr/local/sbin/monitoring-agent
sudo chown root:root /usr/local/sbin/monitoring-agent
sudo chmod 755 /usr/local/sbin/monitoring-agent
```

### When NOT to Use

❌ **Incorrect**:

```bash
# DON'T: User-accessible scripts (use /usr/local/bin)
sudo cp user-script.sh /usr/local/sbin/user-script # Wrong!

# DON'T: Duplicate distribution tools
sudo cp custom-systemctl /usr/local/sbin/systemctl # Shadows /usr/bin/systemctl!
```

✅ **Correct**:

```bash
# For user-accessible tools
sudo cp user-script.sh /usr/local/bin/user-script

# For custom wrappers, use different name
sudo cp custom-systemctl /usr/local/sbin/systemctl-wrapper
```

---

## /opt/*/bin - Third-Party Software Packages

### Purpose

**Self-contained third-party applications** that don't integrate with the system package manager:
- Commercial software (Oracle, VMware, IBM)
- Large open-source applications (GitLab, Puppet)
- Vendor-provided packages
- Containerized/bundled applications

### Characteristics

- **Structure**: Each app in `/opt/package-name/`
- **Self-Contained**: All dependencies bundled
- **Integration**: Requires manual PATH/symlink setup
- **Package Manager**: May have own update mechanism

### Typical Structure

```bash
/opt/
├── google/
│ └── chrome/
│ ├── chrome # Main binary
│ ├── lib/ # Bundled libraries
│ └── resources/
├── gitlab/
│ ├── bin/
│ │ ├── gitlab-ctl
│ │ └── gitlab-rake
│ ├── embedded/ # Bundled Ruby, PostgreSQL, etc.
│ └── sv/ # Services
└── puppetlabs/
 └── puppet/
 ├── bin/
 │ ├── puppet
 │ ├── facter
 │ └── hiera
 └── lib/
```

### Real-World Example

```bash
$ ls /opt
google gitlab puppetlabs vmware oracle

$ ls /opt/gitlab/bin
gitlab-ctl gitlab-psql gitlab-rails gitlab-rake gitlab-runner

# Binaries NOT in PATH by default
$ which gitlab-ctl
gitlab-ctl not found

# Must create symlinks or add to PATH
$ sudo ln -s /opt/gitlab/bin/gitlab-ctl /usr/local/bin/gitlab-ctl
$ which gitlab-ctl
/usr/local/bin/gitlab-ctl
```

### Who Manages It?

- **Vendor**: Provides installer/updater
- **System Administrator**: Installation, integration, updates
- **NOT**: Distribution package manager (usually)

### When to Use

✅ **Appropriate Use Cases**:

```bash
# ✅ Installing vendor-provided software
sudo mkdir /opt/myapp
sudo tar -xzf myapp-1.2.3.tar.gz -C /opt/myapp
sudo ln -s /opt/myapp/bin/myapp /usr/local/bin/myapp

# ✅ Complex application with many dependencies
sudo mkdir /opt/gitlab
sudo dpkg -i gitlab-ee.deb # Installs to /opt/gitlab

# ✅ Commercial software
sudo sh oracle-installer.run # → /opt/oracle
```

### When NOT to Use

❌ **Incorrect**:

```bash
# DON'T: Simple single-binary tools
sudo mkdir /opt/terraform # Overkill! Use /usr/local/bin

# DON'T: Package-manager available software
sudo tar -xzf python-3.12.tar.gz -C /opt/python # Use apt/dnf instead
```

✅ **Correct**:

```bash
# For simple binaries
sudo cp terraform /usr/local/bin/terraform

# For package-managed software
sudo apt install python3.12
```

---

## The UsrMerge: Modern Simplification

### Background

**Problem**: Historical separation of `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin` caused complexity:
- Duplicate binaries (e.g., `/bin/sh` and `/usr/bin/sh`)
- Confusion about placement
- Incompatibility with modern filesystems (everything in one partition)

**Solution**: **UsrMerge** consolidates directories:
- `/bin` → `/usr/bin` (symlink)
- `/sbin` → `/usr/sbin` (symlink)
- `/lib` → `/usr/lib` (symlink)
- `/lib64` → `/usr/lib64` (symlink)

### Distribution Status

| Distribution | Status | Implementation |
|--------------|--------|----------------|
| Fedora 17+ | ✅ Complete | Since 2012 |
| Arch Linux | ✅ Complete | Since 2013 |
| Debian 10+ | ✅ Default | Since 2019 |
| Ubuntu 22.04+ | ✅ Default | Since 2022 |
| RHEL 9+ | ✅ Complete | Since 2022 |
| openSUSE | ✅ Complete | Since 2020 |
| Gentoo | ⚠️ Optional | User choice |
| Slackware | ❌ Not merged | Traditional FHS |

### Real-World Example

```bash
# Modern system (Ubuntu 24.04, Fedora 39)
$ ls -l /bin
lrwxrwxrwx 1 root root 7 Jan 15 2024 /bin -> usr/bin

$ ls -l /sbin
lrwxrwxrwx 1 root root 8 Jan 15 2024 /sbin -> usr/sbin

# All binaries actually in /usr/bin
$ ls -i /bin/bash /usr/bin/bash
12345678 /bin/bash
12345678 /usr/bin/bash # Same inode = same file

# Old system (Ubuntu 18.04, CentOS 7)
$ ls -ld /bin
drwxr-xr-x 2 root root 4096 /bin # Real directory
```

### Implications

✅ **Benefits**:
- Simplified mental model
- Reduced duplication
- Easier package management
- Aligns with modern single-partition systems

⚠️ **Considerations**:
- Scripts hardcoding `/bin/bash` still work (symlink)
- Package managers handle migration automatically
- No user action required

### Migration Example

```bash
# Debian/Ubuntu UsrMerge package
sudo apt install usrmerge # Automated migration

# Manual check
$ dpkg -l | grep usrmerge
ii usrmerge 25 all Convert the system to the merged /usr directories scheme
```

---

## Decision Tree: Where Should I Install?

### Flowchart

```
Is this a distribution-provided package?
├─ YES → Use package manager (apt/dnf/pacman)
│ → Installs to /usr/bin or /usr/sbin automatically
│
└─ NO → Is this from a vendor (Oracle, VMware, GitLab)?
 ├─ YES → /opt/vendor-name/
 │ └─ Symlink to /usr/local/bin if needed
 │
 └─ NO → Are you compiling from source?
 ├─ YES →./configure --prefix=/usr/local
 │ → Installs to /usr/local/bin or /usr/local/sbin
 │
 └─ NO → Is this a single binary or script?
 ├─ YES → /usr/local/bin (user) or /usr/local/sbin (admin)
 │
 └─ NO → Is this a complex multi-file application?
 └─ YES → /opt/app-name/ with symlink to /usr/local/bin
```

### Quick Reference Table

| Software Type | Installation Location | Method |
|---------------|----------------------|--------|
| System package (Python, Git, Nginx) | `/usr/bin`, `/usr/sbin` | `apt install`, `dnf install` |
| Compiled from source (custom build) | `/usr/local/bin`, `/usr/local/sbin` | `make install` |
| Single custom script | `/usr/local/bin` | `sudo cp script.sh /usr/local/bin/` |
| Admin-only script | `/usr/local/sbin` | `sudo cp admin.sh /usr/local/sbin/` |
| Vendor software (GitLab, Oracle) | `/opt/vendor-name/` | Vendor installer → symlink to `/usr/local/bin` |
| Simple third-party binary (Terraform) | `/usr/local/bin` | `sudo cp terraform /usr/local/bin/` |
| Container tools (Docker binaries) | `/usr/bin` (via package) | `apt install docker-ce` |

---

## Comparison Table

| Directory | Essential? | Privilege | Manager | Size | Example Commands |
|-----------|------------|-----------|---------|------|------------------|
| `/bin` | ✅ Boot-required | User | Distribution | 10-50 MB | `ls`, `cp`, `bash`, `grep` |
| `/sbin` | ✅ Boot-required | Root | Distribution | 10-30 MB | `init`, `fsck`, `mount`, `ip` |
| `/usr/bin` | ❌ Optional | User | Distribution | 1-3 GB | `python3`, `git`, `vim`, `docker` |
| `/usr/sbin` | ❌ Optional | Root | Distribution | 100-500 MB | `systemctl`, `apache2`, `useradd` |
| `/usr/local/bin` | ❌ Optional | User | Administrator | 10-500 MB | Custom scripts, compiled tools |
| `/usr/local/sbin` | ❌ Optional | Root | Administrator | 1-100 MB | Custom admin tools, daemons |
| `/opt/*/bin` | ❌ Optional | Mixed | Vendor/Admin | 100 MB-10 GB | `gitlab-ctl`, `oracle`, `vmware` |

### PATH Priority (Standard)

```bash
# Root user
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Regular user
/usr/local/bin:/usr/bin:/bin:/usr/games:/snap/bin
```

**Priority Order** (first match wins):
1. `/usr/local/sbin` (root only) - Custom admin tools
2. `/usr/local/bin` - Custom user tools
3. `/usr/sbin` (root only) - Distribution admin tools
4. `/usr/bin` - Distribution user tools
5. `/sbin` (root only) - Essential admin tools
6. `/bin` - Essential user tools

---

## Best Practices

### 1. Respect the Hierarchy

✅ **DO**:
- Use package managers for distribution software
- Install custom builds to `/usr/local`
- Use `/opt` for self-contained vendor software
- Check `which` and `type` before installing

❌ **DON'T**:
- Manually copy files to `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`
- Mix package-managed and manual installations in same directory
- Assume `/usr/local` exists (create if needed: `sudo mkdir -p /usr/local/bin`)

### 2. Use Version Management

```bash
# ✅ Install specific versions to /usr/local with version suffix
sudo cp python3.12 /usr/local/bin/python3.12
sudo ln -s /usr/local/bin/python3.12 /usr/local/bin/python3

# ✅ Use update-alternatives for version switching (Debian/Ubuntu)
sudo update-alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.12 1
```

### 3. Maintain Clean /usr/local

```bash
# ✅ Keep manifest of manual installations
sudo tee /usr/local/README.txt <<EOF
terraform 1.6.0 - Installed 2024-01-15 by alice
kubectl 1.28.0 - Installed 2024-01-20 by bob
custom-backup.sh - Installed 2024-02-01 by alice
EOF

# ✅ Use stow for organized /usr/local management
cd /usr/local/src
sudo stow -t /usr/local/bin myapp-1.2
```

### 4. Symlink Strategy for /opt

```bash
# ✅ Install to /opt, symlink to /usr/local/bin
sudo tar -xzf gitlab.tar.gz -C /opt/
sudo ln -s /opt/gitlab/bin/gitlab-ctl /usr/local/bin/gitlab-ctl

# ✅ Update PATH for entire application
echo 'export PATH="/opt/gitlab/bin:$PATH"' | sudo tee /etc/profile.d/gitlab.sh
```

### 5. Security Considerations

```bash
# ✅ Set proper ownership and permissions
sudo chown root:root /usr/local/bin/my-script
sudo chmod 755 /usr/local/bin/my-script # rwxr-xr-x

# ✅ For admin-only tools
sudo chown root:root /usr/local/sbin/admin-tool
sudo chmod 700 /usr/local/sbin/admin-tool # rwx------ (root only)

# ❌ NEVER make scripts world-writable
sudo chmod 777 /usr/local/bin/script # DANGEROUS!
```

### 6. Documentation

```bash
# ✅ Add man pages for custom tools
sudo cp my-tool.1 /usr/local/share/man/man1/
sudo mandb # Update man database

# ✅ Include --help and --version
my-tool --help
my-tool --version
```

---

## Common Mistakes

### Mistake 1: Installing to /usr/bin Manually

❌ **Wrong**:
```bash
sudo cp ~/Downloads/my-app /usr/bin/my-app
```

**Problem**: Conflicts with package manager, breaks on system updates

✅ **Correct**:
```bash
sudo cp ~/Downloads/my-app /usr/local/bin/my-app
```

---

### Mistake 2: Ignoring PATH Order

❌ **Wrong**:
```bash
# Installing older version to /usr/local/bin
sudo cp python3.9 /usr/local/bin/python3
# But /usr/bin/python3 (3.12) is already in PATH later
# User expects 3.9 but gets 3.12!
```

**Problem**: PATH priority misunderstood

✅ **Correct**:
```bash
$ which python3
/usr/local/bin/python3 # /usr/local/bin comes BEFORE /usr/bin
# Now correct version is used
```

---

### Mistake 3: Forgetting to Update PATH for /opt

❌ **Wrong**:
```bash
sudo tar -xzf myapp.tar.gz -C /opt/myapp
# User runs 'myapp' → command not found
```

**Problem**: `/opt/myapp/bin` not in PATH

✅ **Correct**:
```bash
sudo tar -xzf myapp.tar.gz -C /opt/myapp
sudo ln -s /opt/myapp/bin/myapp /usr/local/bin/myapp
# OR
echo 'export PATH="/opt/myapp/bin:$PATH"' | sudo tee /etc/profile.d/myapp.sh
```

---

### Mistake 4: Using /usr/local for Package-Managed Software

❌ **Wrong**:
```bash
sudo apt install nodejs # → /usr/bin/node
sudo cp /usr/bin/node /usr/local/bin/node # "For safety"
```

**Problem**: Duplicate binaries, confusion, wasted space

✅ **Correct**:
```bash
sudo apt install nodejs # /usr/bin/node is fine
# OR for custom version:
sudo apt remove nodejs
./configure --prefix=/usr/local && make && sudo make install
```

---

### Mistake 5: Not Checking Existing Installations

❌ **Wrong**:
```bash
sudo cp python3 /usr/local/bin/python3 # Overwrites existing!
```

**Problem**: May break existing scripts/apps

✅ **Correct**:
```bash
$ which python3
/usr/bin/python3

$ /usr/bin/python3 --version
Python 3.10.12

# Install new version with different name
sudo cp python3.12 /usr/local/bin/python3.12
sudo ln -s /usr/local/bin/python3.12 /usr/local/bin/python3
```

---

### Mistake 6: Assuming /usr/local Exists

❌ **Wrong**:
```bash
sudo cp script.sh /usr/local/bin/script.sh
# Error: /usr/local/bin: No such file or directory (on minimal systems)
```

**Problem**: Some minimal installations don't create `/usr/local` directories

✅ **Correct**:
```bash
sudo mkdir -p /usr/local/bin # Create if needed
sudo cp script.sh /usr/local/bin/script.sh
```

---

### Mistake 7: Using /opt for Simple Binaries

❌ **Wrong**:
```bash
sudo mkdir /opt/terraform
sudo cp terraform /opt/terraform/terraform
sudo ln -s /opt/terraform/terraform /usr/local/bin/terraform
```

**Problem**: Overcomplicated for a single binary

✅ **Correct**:
```bash
sudo cp terraform /usr/local/bin/terraform
sudo chmod +x /usr/local/bin/terraform
```

---

### Mistake 8: Hardcoding Shebangs to /usr/bin

❌ **Fragile**:
```bash
#!/usr/bin/python3 # Fails if only in /usr/local/bin/python3
```

**Problem**: Breaks if Python is in `/usr/local/bin` instead

✅ **Portable**:
```bash
#!/usr/bin/env python3 # Searches PATH
```

---

## Summary Checklist

Before installing a binary, ask:

- [ ] **Is it from my distribution's repos?** → Use `apt`/`dnf`/`pacman`
- [ ] **Am I compiling from source?** → Use `./configure --prefix=/usr/local`
- [ ] **Is it a single binary/script?** → Use `/usr/local/bin` or `/usr/local/sbin`
- [ ] **Is it vendor-provided (GitLab, Oracle)?** → Use `/opt/vendor-name/`
- [ ] **Does /usr/local exist?** → Create with `sudo mkdir -p /usr/local/bin`
- [ ] **Did I check for conflicts?** → Run `which`, `type`, `ls /usr/local/bin`
- [ ] **Did I set correct permissions?** → `sudo chmod 755` or `700` for admin tools
- [ ] **Did I update PATH if needed?** → Symlink to `/usr/local/bin` or add to `/etc/profile.d/`

---

## Additional Resources

- **FHS 3.0 Specification**: https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
- **UsrMerge (Debian)**: https://wiki.debian.org/UsrMerge
- **GNU Coding Standards** (installation): https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
- **PATH Best Practices**: `man hier` (filesystem hierarchy)

---

**Document Version**: 1.0
**Last Updated**: 2024-01-15
**Author**: Linux Binary Hierarchy Working Group
**Lines**: 1050+
