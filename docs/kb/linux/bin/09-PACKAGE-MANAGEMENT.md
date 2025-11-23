---
id: linux-09-package-management
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

# Package Management and Binary Installation

**Part of Linux Bin Directories Knowledge Base**

## Table of Contents
1. [Overview](#overview)
2. [How Package Managers Handle Binaries](#how-package-managers-handle-binaries)
3. [APT (Debian/Ubuntu)](#apt-debianubuntu)
4. [YUM/DNF (RHEL/Fedora)](#yumdnf-rhelfedora)
5. [Pacman (Arch Linux)](#pacman-arch-linux)
6. [Package Manager vs Manual Installation](#package-manager-vs-manual-installation)
7. [Binary Installation Paths](#binary-installation-paths)
8. [Creating Custom DEB Packages](#creating-custom-deb-packages)
9. [Creating Custom RPM Packages](#creating-custom-rpm-packages)
10. [Alternatives System](#alternatives-system)
11. [Clean Uninstallation](#clean-uninstallation)
12. [Troubleshooting Package Conflicts](#troubleshooting-package-conflicts)

---

## Overview

Package managers are the primary way binaries get installed on Linux systems. Understanding how they work is crucial for managing the commands available in your bin directories.

### Key Concepts

**Package managers handle**:
- Binary installation to standard locations
- Dependency resolution
- Version management
- Clean removal
- System-wide updates

**Manual installation handles**:
- Custom/proprietary software
- Latest versions not in repos
- Development versions
- Local/custom tools

---

## How Package Managers Handle Binaries

### Installation Process

When you install a package, the package manager:

1. **Downloads** the package file (.deb,.rpm,.pkg.tar.zst)
2. **Verifies** checksums and signatures
3. **Resolves** dependencies
4. **Extracts** files to system locations
5. **Runs** post-installation scripts
6. **Updates** the package database

### Binary Placement

```bash
# System binaries (package manager controlled)
/usr/bin/ # User commands (primary location)
/usr/sbin/ # System administration commands
/bin/ # Essential system binaries (often symlink to /usr/bin)
/sbin/ # Essential system admin binaries (often symlink to /usr/sbin)

# Local binaries (administrator controlled)
/usr/local/bin/ # Locally compiled/installed programs
/usr/local/sbin/ # Locally installed admin tools
/opt/*/bin/ # Optional/third-party software
```

### Package Database

```bash
# ✅ Query what package owns a binary
dpkg -S /usr/bin/git # Debian/Ubuntu
rpm -qf /usr/bin/git # RHEL/Fedora
pacman -Qo /usr/bin/git # Arch

# Example output
git is owned by git 2.34.1-1ubuntu1.10
```

---

## APT (Debian/Ubuntu)

### Basic Binary Installation

```bash
# ✅ Install a package with binaries
sudo apt update
sudo apt install git

# This installs:
# /usr/bin/git
# /usr/bin/git-shell
# /usr/bin/git-upload-pack
#... and many more
```

### Finding Packages That Provide a Binary

```bash
# ✅ Find package that provides a binary (installed)
dpkg -S $(which python3)
# Output: python3-minimal: /usr/bin/python3

# ✅ Find package that provides a binary (not installed)
apt-file search /usr/bin/node
# First install apt-file:
sudo apt install apt-file
sudo apt-file update

# Then search:
apt-file search /usr/bin/node
# Output: nodejs: /usr/bin/node
```

### Listing Package Contents

```bash
# ✅ List all files in a package
dpkg -L git | grep /bin/
# Output:
# /usr/bin/git
# /usr/bin/git-receive-pack
# /usr/bin/git-shell
# /usr/bin/git-upload-archive
# /usr/bin/git-upload-pack

# ✅ List binaries before installing
apt-cache show nodejs | grep "^Filename:"
apt download nodejs
dpkg -c nodejs_*.deb | grep /bin/
rm nodejs_*.deb
```

### Alternatives System

```bash
# ✅ Configure which version of Python runs as 'python'
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 2

# Choose which one to use
sudo update-alternatives --config python
# Interactive menu:
# Selection Path Priority Status
# 0 /usr/bin/python3.11 2 auto mode
# 1 /usr/bin/python3.10 1 manual mode
# * 2 /usr/bin/python3.11 2 manual mode

# ✅ Check current alternatives
update-alternatives --display python
```

### Holding Packages

```bash
# ✅ Prevent a package from being upgraded
sudo apt-mark hold nodejs
# nodejs set on hold.

# Check held packages
apt-mark showhold

# Unhold
sudo apt-mark unhold nodejs
```

### Installing from.deb Files

```bash
# ✅ Install a downloaded.deb package
sudo dpkg -i package.deb

# If dependencies are missing:
sudo apt install -f # Fix dependencies

# ❌ Wrong: Installing without fixing dependencies
sudo dpkg -i complex-package.deb
# dpkg: dependency problems prevent configuration...

# ✅ Better: Use apt for local files (handles dependencies)
sudo apt install./package.deb
```

### PPAs (Personal Package Archives)

```bash
# ✅ Add a PPA for newer versions
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.12

# This installs to:
/usr/bin/python3.12

# ✅ Remove a PPA
sudo add-apt-repository --remove ppa:deadsnakes/ppa
```

### Purging vs Removing

```bash
# ❌ Remove (leaves config files)
sudo apt remove nginx
# Binaries removed, but /etc/nginx/ remains

# ✅ Purge (removes everything)
sudo apt purge nginx
# Binaries AND config files removed

# ✅ Remove unused dependencies
sudo apt autoremove
```

---

## YUM/DNF (RHEL/Fedora)

### Basic Binary Installation

```bash
# ✅ Install a package (RHEL 7 and earlier)
sudo yum install git

# ✅ Install a package (RHEL 8+, Fedora)
sudo dnf install git

# Both install to:
# /usr/bin/git
# /usr/libexec/git-core/*
```

### Finding Packages

```bash
# ✅ Find what package provides a binary
dnf provides /usr/bin/node
# Output: nodejs-1:16.14.0-1.fc35.x86_64: JavaScript runtime

# ✅ Search for packages
dnf search nodejs

# ✅ Get package information
dnf info nodejs
```

### Listing Package Contents

```bash
# ✅ List files in an installed package
rpm -ql git | grep /bin/

# ✅ List files in an uninstalled package
dnf repoquery -l nodejs | grep /bin/

# ✅ List files in a downloaded RPM
rpm -qlp nodejs-16.14.0-1.fc35.x86_64.rpm
```

### Package Groups

```bash
# ✅ Install a group of related packages
sudo dnf groupinstall "Development Tools"
# Installs: gcc, make, autoconf, automake, etc.

# ✅ List available groups
dnf grouplist

# ✅ See what's in a group
dnf groupinfo "Development Tools"
```

### Managing Repositories

```bash
# ✅ List enabled repositories
dnf repolist

# ✅ Add a new repository
sudo dnf config-manager --add-repo https://example.com/repo/fedora.repo

# ✅ Enable/disable a repository
sudo dnf config-manager --set-enabled powertools
sudo dnf config-manager --set-disabled powertools

# ✅ Install EPEL (Extra Packages for Enterprise Linux)
sudo dnf install epel-release
```

### Installing Local RPMs

```bash
# ✅ Install an RPM file
sudo dnf install./package.rpm
# OR
sudo rpm -ivh package.rpm

# Options:
# -i: install
# -v: verbose
# -h: hash marks (progress)

# ✅ Upgrade an existing package
sudo rpm -Uvh package.rpm

# ❌ Force installation (dangerous)
sudo rpm -ivh --force package.rpm # Overwrites files
sudo rpm -ivh --nodeps package.rpm # Ignores dependencies
```

### Alternatives System

```bash
# ✅ Set up alternatives (similar to Debian)
sudo alternatives --install /usr/bin/python python /usr/bin/python3.9 1
sudo alternatives --install /usr/bin/python python /usr/bin/python3.11 2

# Configure
sudo alternatives --config python

# Display current settings
alternatives --display python
```

### Version Locking

```bash
# ✅ Install yum-plugin-versionlock
sudo dnf install python3-dnf-plugin-versionlock

# ✅ Lock a package version
sudo dnf versionlock add nodejs

# ✅ List locked packages
dnf versionlock list

# ✅ Remove lock
sudo dnf versionlock delete nodejs
```

---

## Pacman (Arch Linux)

### Basic Binary Installation

```bash
# ✅ Install a package
sudo pacman -S git

# ✅ Update package database and install
sudo pacman -Sy git

# ✅ Full system upgrade
sudo pacman -Syu
```

### Finding Packages

```bash
# ✅ Search for packages
pacman -Ss nodejs

# ✅ Find what package owns a file
pacman -Qo /usr/bin/node
# Output: /usr/bin/node is owned by nodejs 18.12.1-1

# ✅ Find package that would provide a file (not installed)
pacman -F /usr/bin/node
# First update file database:
sudo pacman -Fy
```

### Listing Package Contents

```bash
# ✅ List files in an installed package
pacman -Ql nodejs | grep /bin/

# ✅ List files in a package (not installed)
pacman -Fl nodejs | grep /bin/
```

### AUR (Arch User Repository)

```bash
# ✅ Install an AUR helper (yay)
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# ✅ Install AUR packages
yay -S nvm # Node Version Manager from AUR

# ⚠️ AUR packages are user-maintained
# Always review PKGBUILD before installing:
yay -G nvm # Download PKGBUILD
cd nvm
cat PKGBUILD # Review the build script
makepkg -si # Build and install
```

### Creating Custom Packages

```bash
# ✅ Basic PKGBUILD for a custom binary
cat > PKGBUILD << 'EOF'
# Maintainer: Your Name <email@example.com>
pkgname=mycustomtool
pkgver=1.0
pkgrel=1
pkgdesc="My custom tool"
arch=('x86_64')
url="https://example.com/mycustomtool"
license=('MIT')
depends=
source=("mycustomtool-${pkgver}.tar.gz")
sha256sums=('SKIP')

build {
 cd "$srcdir/$pkgname-$pkgver"
 make
}

package {
 cd "$srcdir/$pkgname-$pkgver"
 install -Dm755 mycustomtool "$pkgdir/usr/bin/mycustomtool"
}
EOF

# Build the package
makepkg -s # Build with dependency checking

# Install
sudo pacman -U mycustomtool-1.0-1-x86_64.pkg.tar.zst
```

### Package Removal

```bash
# ✅ Remove a package
sudo pacman -R nodejs

# ✅ Remove package and unused dependencies
sudo pacman -Rs nodejs

# ✅ Remove package, dependencies, and config files
sudo pacman -Rns nodejs

# ⚠️ Force removal (dangerous)
sudo pacman -Rdd nodejs # Ignore dependencies
```

---

## Package Manager vs Manual Installation

### When to Use Package Manager

**✅ Use package manager when**:
- Software is available in official repos
- You want automatic updates
- You need dependency management
- You want easy uninstallation
- Multiple users need access

```bash
# ✅ Package manager advantages
sudo apt install postgresql
# - Installs to /usr/bin/
# - Handles dependencies automatically
# - Creates systemd service
# - Updates with 'apt upgrade'
# - Removes cleanly with 'apt purge'
```

### When to Install Manually

**✅ Install manually when**:
- Need latest version (not in repos)
- Building from source with custom options
- Installing proprietary software
- Need multiple versions simultaneously
- Software isn't packaged

```bash
# ✅ Manual installation to /usr/local
cd /tmp
wget https://example.com/tool-latest.tar.gz
tar xzf tool-latest.tar.gz
cd tool-latest
./configure --prefix=/usr/local
make
sudo make install

# Installs to:
# /usr/local/bin/tool
# /usr/local/lib/tool/
# /usr/local/share/tool/
```

### Hybrid Approach

```bash
# ✅ Use package for base, manual for specific versions
# System Python via package manager
sudo apt install python3

# Latest Python built from source
cd /tmp
wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz
tar xzf Python-3.12.0.tgz
cd Python-3.12.0
./configure --prefix=/usr/local/python3.12 --enable-optimizations
make -j$(nproc)
sudo make altinstall # altinstall = doesn't overwrite /usr/local/bin/python3

# Now you have:
/usr/bin/python3 # System version (3.10)
/usr/local/bin/python3.12 # Latest version
```

---

## Binary Installation Paths

### Standard Locations

```bash
# Package manager controlled
/usr/bin/ # User programs (package manager primary)
/usr/sbin/ # System admin tools (package manager)

# Manually installed
/usr/local/bin/ # User programs (manual installation)
/usr/local/sbin/ # System admin tools (manual)

# Optional software
/opt/bin/ # Third-party software
/opt/*/bin/ # Per-application bin directories
```

### PATH Priority

```bash
# ✅ Typical PATH order
echo $PATH
# /usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

# /usr/local/bin comes FIRST
# This means manually installed tools override packaged ones

# Example:
/usr/bin/python3 # Version 3.10 (from apt)
/usr/local/bin/python3 # Version 3.12 (manually built)

# When you type 'python3', you get 3.12
```

### Best Practices

```bash
# ✅ Package manager installs
# Let package manager use /usr/bin
sudo apt install nodejs
# → /usr/bin/node

# ✅ Manual builds
# Use /usr/local prefix
./configure --prefix=/usr/local
sudo make install
# → /usr/local/bin/node

# ✅ Third-party software
# Use /opt for self-contained apps
sudo mkdir -p /opt/myapp/bin
sudo cp myapp /opt/myapp/bin/
# Add to PATH in /etc/profile.d/
echo 'export PATH="/opt/myapp/bin:$PATH"' | sudo tee /etc/profile.d/myapp.sh

# ❌ Don't mix approaches
sudo cp mymanualprogram /usr/bin/ # Bad: conflicts with package manager
```

---

## Creating Custom DEB Packages

### Simple Binary Package

```bash
# ✅ Create a directory structure
mkdir -p mypackage_1.0/DEBIAN
mkdir -p mypackage_1.0/usr/bin
mkdir -p mypackage_1.0/usr/share/doc/mypackage

# Create the control file
cat > mypackage_1.0/DEBIAN/control << 'EOF'
Package: mypackage
Version: 1.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Your Name <email@example.com>
Description: My custom package
 This is a longer description
 of what my package does.
EOF

# Copy your binary
cp /path/to/mybinary mypackage_1.0/usr/bin/
chmod 755 mypackage_1.0/usr/bin/mybinary

# Build the package
dpkg-deb --build mypackage_1.0

# Install it
sudo dpkg -i mypackage_1.0.deb
```

### Advanced Package with Dependencies

```bash
# ✅ Create control file with dependencies
cat > mypackage_2.0/DEBIAN/control << 'EOF'
Package: mypackage
Version: 2.0
Section: utils
Priority: optional
Architecture: amd64
Depends: python3 (>= 3.8), libc6 (>= 2.31)
Maintainer: Your Name <email@example.com>
Description: My custom package
 This version has dependencies.
EOF

# Add post-installation script
cat > mypackage_2.0/DEBIAN/postinst << 'EOF'
#!/bin/bash
set -e

# Create config directory
mkdir -p /etc/mypackage

# Set up default config
if [ ! -f /etc/mypackage/config ]; then
 echo "# My Package Config" > /etc/mypackage/config
fi

# Run any initialization
/usr/bin/mypackage --init

exit 0
EOF

chmod 755 mypackage_2.0/DEBIAN/postinst

# Add pre-removal script
cat > mypackage_2.0/DEBIAN/prerm << 'EOF'
#!/bin/bash
set -e

# Stop any running services
systemctl stop mypackage || true

exit 0
EOF

chmod 755 mypackage_2.0/DEBIAN/prerm

# Build
dpkg-deb --build mypackage_2.0
```

### Using debhelper (Professional Approach)

```bash
# ✅ Install build tools
sudo apt install debhelper dh-make

# Create source directory
mkdir mypackage-1.0
cd mypackage-1.0

# Create debian/ directory
dh_make --createorig --single --yes

# Edit debian/control
cat > debian/control << 'EOF'
Source: mypackage
Section: utils
Priority: optional
Maintainer: Your Name <email@example.com>
Build-Depends: debhelper (>= 10)
Standards-Version: 4.5.0

Package: mypackage
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}
Description: My package
 Long description here.
EOF

# Build the package
dpkg-buildpackage -us -uc

# Result:../mypackage_1.0_amd64.deb
```

---

## Creating Custom RPM Packages

### Basic RPM Package

```bash
# ✅ Install RPM build tools
sudo dnf install rpm-build rpmdevtools

# Set up build environment
rpmdev-setuptree
# Creates:
# ~/rpmbuild/BUILD
# ~/rpmbuild/RPMS
# ~/rpmbuild/SOURCES
# ~/rpmbuild/SPECS
# ~/rpmbuild/SRPMS

# Create spec file
cat > ~/rpmbuild/SPECS/mypackage.spec << 'EOF'
Name: mypackage
Version: 1.0
Release: 1%{?dist}
Summary: My custom package

License: MIT
Source0: %{name}-%{version}.tar.gz

%description
This is my custom package that does something useful.

%prep
%setup -q

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%files
%{_bindir}/mypackage
%doc README.md
%license LICENSE

%changelog
* Sat Nov 09 2024 Your Name <email@example.com> - 1.0-1
- Initial package
EOF

# Create source tarball
tar czf ~/rpmbuild/SOURCES/mypackage-1.0.tar.gz mypackage-1.0/

# Build the RPM
rpmbuild -ba ~/rpmbuild/SPECS/mypackage.spec

# Result: ~/rpmbuild/RPMS/x86_64/mypackage-1.0-1.fc35.x86_64.rpm
```

### RPM with Dependencies

```bash
# ✅ Spec file with dependencies
cat > ~/rpmbuild/SPECS/mypackage.spec << 'EOF'
Name: mypackage
Version: 2.0
Release: 1%{?dist}
Summary: My custom package

License: MIT
Source0: %{name}-%{version}.tar.gz

Requires: python3 >= 3.8
Requires: bash
BuildRequires: gcc
BuildRequires: make

%description
This is my custom package with dependencies.

%prep
%setup -q

%build
./configure --prefix=/usr
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
# Post-installation script
mkdir -p /etc/mypackage
systemctl daemon-reload

%preun
# Pre-uninstallation script
if [ $1 -eq 0 ]; then
 systemctl stop mypackage
fi

%files
%{_bindir}/mypackage
%config(noreplace) %{_sysconfdir}/mypackage/config
%{_unitdir}/mypackage.service

%changelog
* Sat Nov 09 2024 Your Name <email@example.com> - 2.0-1
- Added systemd service
- Added configuration file
EOF
```

---

## Alternatives System

### Debian update-alternatives

```bash
# ✅ Set up alternatives for multiple Java versions
sudo update-alternatives --install \
 /usr/bin/java java /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1

sudo update-alternatives --install \
 /usr/bin/java java /usr/lib/jvm/java-17-openjdk-amd64/bin/java 2

# Configure which to use
sudo update-alternatives --config java

# Check current selection
update-alternatives --display java
```

### Red Hat alternatives

```bash
# ✅ Same concept, different command name
sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 2

sudo alternatives --config python3
```

---

## Clean Uninstallation

### Complete Removal

```bash
# ✅ Debian/Ubuntu: Remove package and configs
sudo apt purge package-name
sudo apt autoremove

# ✅ RHEL/Fedora: Remove package
sudo dnf remove package-name
sudo dnf autoremove

# ✅ Arch: Remove package and dependencies
sudo pacman -Rns package-name
```

### Manual Cleanup

```bash
# ✅ Find leftover files
sudo find / -name "*package-name*" 2>/dev/null

# ✅ Remove manually installed binaries
sudo rm /usr/local/bin/mybinary
sudo rm -rf /usr/local/lib/mypackage
sudo rm -rf /etc/mypackage
```

---

## Troubleshooting Package Conflicts

### File Conflicts

```bash
# ❌ Error: files conflict
sudo apt install package-new
# dpkg: error processing archive:
# trying to overwrite '/usr/bin/tool', which is also in package package-old

# ✅ Solution 1: Remove old package first
sudo apt remove package-old
sudo apt install package-new

# ✅ Solution 2: Use alternatives
sudo update-alternatives --install /usr/bin/tool tool /usr/bin/tool-old 1
sudo update-alternatives --install /usr/bin/tool tool /usr/bin/tool-new 2
```

### Dependency Conflicts

```bash
# ❌ Error: dependency issues
# The following packages have unmet dependencies:
# package-a: Depends: libfoo (>= 2.0) but 1.8 is installed

# ✅ Solution: Update dependencies
sudo apt update
sudo apt install libfoo

# ✅ Or: Install from backports
sudo apt install -t bullseye-backports package-a
```

This comprehensive guide covers package management from basic installation through advanced custom package creation, providing the foundation for managing binaries across all major Linux distributions.
