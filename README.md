# OS Sundae - Custom Debian-based Live ISO

youtube > https://youtu.be/okgBv6zRdQ8

OS Sundae - Live Rescue & Data Recovery System
Overview
OS Sundae is a non-installable, read-only Live OS designed for emergency data recovery and system troubleshooting. It boots directly from a USB drive without modifying the host computer’s storage, making it ideal for:

🔧 Recovering files from corrupted systems

🔓 Bypassing login on locked machines (ethical use only)

🛠️ Repairing partitions (GParted, TestDisk, etc.)

📡 Network diagnostics (Nmap, Wireshark, Aircrack-ng)

⚠️ No installation or persistent changes – Every reboot resets the system to its default state.

Key Features
1. No Installation Required
- Runs entirely from USB/CD
- Does not touch the host OS storage (unless manually mounted)
- No traces left after shutdown

2. Data Recovery Tools
- Tool	Purpose
- GParted	Partition management
- TestDisk	Recover lost partitions
- extundelete	Undelete files (ext3/ext4)
- scalpel	File carving from damaged disks
- ddrescue	Clone failing drives safely
  
3. System Access & Forensics
- Autologin enabled (User: sundae, Password: sundae)
- Root access disabled (security precaution)
- Preinstalled tools for password reset (chntpw, etc.)
- SSH enabled for remote access (use responsibly)

5. Security & Privacy
- All changes are temporary (RAM-only)
- No persistent storage unless manually configured
- Firewall & network tools included (Nmap, Wireshark)
- 
## Warning
⚠️ **This ISO contains intentional security weaknesses for educational purposes:**
- Default credentials are insecure
- Cron job sets permissive 777 permissions (sample only)
- Root password disabled

⚠️⚠️⚠️ WARNING: Ethical & Legal Use Only
❌ Do NOT use for illegal activities (e.g., unauthorized access).
✅ Intended for:
- IT professionals performing data recovery
- Users repairing their own systems
- Ethical hacking training (with permission)

Do not use in production environments without modification.

## Build Requirements
- Debian/Ubuntu system
- Minimum 20GB disk space
- Internet connection

## Installation

```bash
sudo apt update && sudo apt install live-build git
git clone https://github.com/nanofatdog/linux-os-sundae.git
cd linux-os-sundae

sudo ./create_OS_sundae.sh
```

The ISO will be generated at /root/OSsundae_amd64.iso

### Recommended Repository Structure:
```
OS-sundae/
│
├── OS_sundae_ver1.sh # Main build script
├── README.md # This file
├── LICENSE # License file
├── config/ # Custom configuration files
│ ├── package-lists/ # Package selections
│ └── includes.chroot/ # System modifications
└── samples/ # (Optional) Sample files
└── kodExplorer/ # Web file manager files
```
## How to Use
1 Create a Bootable USB
```
dd if=OSsundae_amd64.iso of=/dev/sdX bs=4M status=progress

(Replace /dev/sdX with your USB device)
```

2 Boot from USB
- Select "Start OS Sundae" in the boot menu
- System auto-logins to XFCE desktop

3 Recover Data
- Use GParted/TestDisk for partition repair
- Mount drives manually (sudo mount /dev/sdX /mnt)
- Copy files to external storage

4 Shutdown Securely
- No data is saved – All changes are lost on reboot.

Key points I emphasized:
1. Clear security warnings upfront
2. Simple build instructions
3. Organized customization section
4. Professional disclaimer
5. Visual hierarchy with emojis
