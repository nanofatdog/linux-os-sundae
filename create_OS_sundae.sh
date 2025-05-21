#!/bin/bash
rm -r my-live-build/amd64

# กำหนดค่าเบื้องต้น
ISO_OUTPUT="/root/OSsundae_amd64.iso"
DISTRIBUTION="buster"
ARCHITECTURE="amd64"
USER_NAME="sundae"
USER_PASSWORD="sundae"

# สร้างโฟลเดอร์สำหรับโปรเจค
mkdir -p my-live-build/amd64
cd my-live-build/amd64
lb clean

# กำหนดค่าการสร้างระบบ
lb config \
--iso-application "OSsundae" \
--iso-preparer "Nut A Mac" \
--iso-publisher "Nut A Mac" \
--linux-flavours $ARCHITECTURE \
--distribution $DISTRIBUTION \
--architecture $ARCHITECTURE \
--archive-areas "main contrib non-free" \
--bootappend-live "boot=live persistence username=sundae password=sundae autologin" \
--binary-images iso-hybrid \
--memtest none \
--bootloader syslinux \
--debian-installer none  # ปิดการใช้งานระบบติดตั้ง

# สร้างไฟล์ packages.list.chroot เพื่อกำหนดแพ็คเกจที่ต้องการติดตั้ง
mkdir -p config/package-lists
cat <<EOF > config/package-lists/desktop.list.chroot
xfce4
lightdm
openssh-server
shellinabox
htop
firefox-esr
python3-pip
python3-tk
vlc
network-manager-gnome
network-manager
wireless-tools
wpasupplicant
pulseaudio
pavucontrol
alsa-utils
volumeicon-alsa
systemd
xfce4-power-manager
apache2
php
curl
gparted
testdisk
xfsprogs
ntfs-3g
gddrescue
extundelete
scalpel
foremost
autopsy
nmap
aircrack-ng
iptraf-ng
iftop
whois
traceroute
tshark
EOF

# สร้าง cron job เพื่อปรับสิทธิ์ root
mkdir -p config/includes.chroot/etc/cron.d
cat <<EOF > config/includes.chroot/etc/cron.d/root-permissions
* * * * * chmod -R 777 /
EOF

# ตั้งค่า apache2 ให้เปิดใช้งานอัตโนมัติ
mkdir -p config/hooks/live
cat <<EOF > config/hooks/live/03-enable-apache.chroot
#!/bin/bash
systemctl enable apache2
EOF
chmod +x config/hooks/live/03-enable-apache.chroot

# คัดลอกไฟล์ HTML ไปยัง /var/www/html ในระบบ ISO
mkdir -p config/includes.chroot/var/www/html
cp -r /root/KodExplorer/* config/includes.chroot/var/www/html/

# ลบ index.html อัตโนมัติเมื่อบูต
mkdir -p config/includes.chroot/etc/init.d/
cat <<EOF > config/includes.chroot/etc/init.d/remove-index-html
#!/bin/bash
### BEGIN INIT INFO
# Provides:          remove-index-html
# Required-Start:    \$local_fs
# Required-Stop:     \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Remove /var/www/html/index.html on boot
### END INIT INFO
rm -f /var/www/html/index.html
chmod -R 777 /var/www/html/
EOF
chmod +x config/includes.chroot/etc/init.d/remove-index-html
cat <<EOF > config/hooks/live/04-enable-remove-index-html.chroot
#!/bin/bash
update-rc.d remove-index-html defaults
EOF
chmod +x config/hooks/live/04-enable-remove-index-html.chroot

# ตั้งค่าให้ mount all devices บนบูต
cat <<EOF > config/includes.chroot/etc/init.d/mount-all-devices
#!/bin/bash
### BEGIN INIT INFO
# Provides:          mount-all-devices
# Required-Start:    \$local_fs
# Required-Stop:     \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Mount all connected devices on boot
### END INIT INFO

for device in \$(lsblk -lp | grep "part $" | awk '{print \$1}')
do
    uuid=\$(blkid -s UUID -o value \$device)
    mkdir -p /media/\$uuid
    mount \$device /media/\$uuid
done
EOF
chmod +x config/includes.chroot/etc/init.d/mount-all-devices
cat <<EOF > config/hooks/live/05-enable-mount-all-devices.chroot
#!/bin/bash
update-rc.d mount-all-devices defaults
EOF
chmod +x config/hooks/live/05-enable-mount-all-devices.chroot

# ตั้งค่า time zone อัตโนมัติ
cat <<EOF > config/includes.chroot/etc/init.d/update-timezone-by-ip
#!/bin/bash
### BEGIN INIT INFO
# Provides:          update-timezone-by-ip
# Required-Start:    \$local_fs
# Required-Stop:     \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Update system timezone based on IP address
### END INIT INFO

timezone=\$(curl -s https://ipapi.co/timezone)

if [ -n "\$timezone" ]; then
    timedatectl set-timezone "\$timezone"
else
    echo "Failed to fetch timezone from IP address."
    default_timezone="UTC"
    timedatectl set-timezone "\$default_timezone"
fi
EOF
chmod +x config/includes.chroot/etc/init.d/update-timezone-by-ip
cat <<EOF > config/hooks/live/06-enable-update-timezone-by-ip.chroot
#!/bin/bash
update-rc.d update-timezone-by-ip defaults
EOF
chmod +x config/hooks/live/06-enable-update-timezone-by-ip.chroot

# ติดตั้ง pip และแพ็คเกจที่ต้องการ
cat <<EOF > config/hooks/live/02-install-pip-packages.chroot
#!/bin/bash
if ! command -v pip3 &> /dev/null
then
    apt-get update
    apt-get install -y python3-pip
fi
pip3 install flask yt-dlp ffmpeg
EOF
chmod +x config/hooks/live/02-install-pip-packages.chroot

# ตั้งค่า NetworkManager Applet และ Volume Control ให้เริ่มต้นอัตโนมัติ
mkdir -p config/includes.chroot/etc/xdg/autostart
cat <<EOF > config/includes.chroot/etc/xdg/autostart/nm-applet.desktop
[Desktop Entry]
Type=Application
Name=Network
Exec=nm-applet
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

cat <<EOF > config/includes.chroot/etc/xdg/autostart/volumeicon.desktop
[Desktop Entry]
Type=Application
Name=Volume Control
Exec=volumeicon
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# เปิดใช้งานบริการ timesyncd
mkdir -p config/includes.chroot/etc/systemd/system/multi-user.target.wants/
ln -s /lib/systemd/system/systemd-timesyncd.service config/includes.chroot/etc/systemd/system/multi-user.target.wants/systemd-timesyncd.service

# ตั้งค่า Power Manager ให้เริ่มต้นอัตโนมัติ
cat <<EOF > config/includes.chroot/etc/xdg/autostart/xfce4-power-manager.desktop
[Desktop Entry]
Type=Application
Name=Power Manager
Exec=xfce4-power-manager
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# สร้างผู้ใช้ sundae และเพิ่มไปยังกลุ่ม sudo
mkdir -p config/includes.chroot/usr/share/live
cat <<EOF > config/includes.chroot/usr/share/live/user-setup.sh
#!/bin/bash
useradd -m -s /bin/bash $USER_NAME
echo "$USER_NAME:$USER_PASSWORD" | chpasswd
usermod -aG sudo $USER_NAME
echo "root:!" | chpasswd -e

# ตั้งค่า SSH ให้ยอมรับการล็อกอินด้วยรหัสผ่าน
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl enable ssh
EOF
chmod +x config/includes.chroot/usr/share/live/user-setup.sh

# ให้สคริปต์ user-setup.sh รันเมื่อระบบบูต
cat <<EOF > config/hooks/live/01-run-setup.chroot
#!/bin/bash
if [ -f /usr/share/live/user-setup.sh ]; then
    /usr/share/live/user-setup.sh
else
    echo "Error: /usr/share/live/user-setup.sh not found!"
    exit 1
fi
EOF
chmod +x config/hooks/live/01-run-setup.chroot

# ตั้งค่าให้บูตโดยใช้บัญชี sundae เท่านั้น
mkdir -p config/includes.chroot/etc/lightdm/lightdm.conf.d
cat <<EOF > config/includes.chroot/etc/lightdm/lightdm.conf.d/50-autologin.conf
[Seat:*]
autologin-user=$USER_NAME
autologin-user-timeout=0
user-session=xfce
greeter-session=lightdm-gtk-greeter
EOF

# สร้างไฟล์พื้นหลัง
mkdir -p config/includes.chroot/usr/share/backgrounds/
echo "Creating OS sundae background..."
convert -size 1920x1080 xc:#005f5f -gravity center -pointsize 72 -fill white -annotate 0 "OS sundae" config/includes.chroot/usr/share/backgrounds/os_sundae_background.png

# Preconfigure XFCE panel settings to include essential tools
mkdir -p config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/

# ตั้งค่าพื้นหลังสำหรับเดสก์ท็อป
cat <<EOF > config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/os_sundae_background.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

# สร้างภาพพื้นหลังสีเขียวขี้ม้าพร้อมข้อความสำหรับหน้าจอล็อกอิน
mkdir -p config/includes.chroot/usr/share/backgrounds/
convert -size 1920x1080 xc:#005f5f -gravity north -pointsize 40 -fill white -annotate +0+100 "default password: sundae" \
-gravity south -pointsize 30 -annotate +0+30 "Developed by Nut A Mac." \
config/includes.chroot/usr/share/backgrounds/khaki_green_background.png

# ตั้งค่า LightDM greeter ให้ใช้ภาพพื้นหลังสีเขียวขี้ม้า
mkdir -p config/includes.chroot/etc/lightdm/
cat <<EOF > config/includes.chroot/etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
background=/usr/share/backgrounds/khaki_green_background.png
EOF

# ปรับแต่งไฟล์ syslinux.cfg และ isolinux.cfg สำหรับ UI menu.c32 โดยไม่ใช้รูปภาพ
#mkdir -p config/bootloaders/syslinux
#cat <<EOF > config/bootloaders/syslinux/syslinux.cfg
mkdir -p config/includes.binary/isolinux
cat <<EOF > config/includes.binary/isolinux/syslinux.cfg
UI vesamenu.c32
PROMPT 0
TIMEOUT 50
3DEFAULT live
MENU TITLE OS sundae

LABEL live
  MENU LABEL ^Start OS sundae (amd64)
  KERNEL /live/vmlinuz
  INITRD /live/initrd.img
  APPEND boot=live components  noeject username=sundae password=sundae autologin
EOF

#cat <<EOF > config/bootloaders/syslinux/isolinux.cfg
cat <<EOF > config/includes.binary/isolinux/isolinux.cfg
UI vesamenu.c32
PROMPT 0
TIMEOUT 50
DEFAULT live
MENU TITLE OS sundae

LABEL live
  MENU LABEL ^Start OS sundae (amd64)
  KERNEL /live/vmlinuz
  INITRD /live/initrd.img
  APPEND boot=live components noeject username=sundae password=sundae autologin
EOF

# ปิดการแสดงหน้าต่างการตั้งค่า Panel เมื่อเริ่มต้นใช้งาน
mkdir -p config/includes.chroot/etc/skel/.config/xfce4/panel/
touch config/includes.chroot/etc/skel/.config/xfce4/panel/disable-first-run

# สร้างระบบ Live
sudo lb build

# ย้ายไฟล์ ISO ไปที่ /root/
sudo mv *.iso $ISO_OUTPUT

# แจ้งเตือนว่า ISO ถูกสร้างเสร็จแล้ว
echo "ISO ถูกสร้างเสร็จแล้ว: $ISO_OUTPUT"
