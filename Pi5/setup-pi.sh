function generate_generate_backup_file_name() {
  echo $1"_bak_"`date "+%Y%m%d_%H%M%S"`
}
function diff_file() {
  echo ""
  diff $diff_switch $1 $2
  echo ""
}

# Disale Swap
sudo swapoff --all && \
sudo apt purge -y --auto-remove dphys-swapfile && \
sudo rm -fr /var/swap
dest_file=/etc/fstab
add_str1="tmpfs           /tmp            tmpfs   defaults,size=256m,noatime,mode=1777  0       0"
add_str2="tmpfs           /var/tmp        tmpfs   defaults,size=16m,noatime,mode=1777  0       0"
add_str3="tmpfs           /var/log        tmpfs   defaults,size=32m,noatime,mode=0755      0       0"
if ! grep -q "$add_str1" $dest_file ; then
  cat <<EOL | sudo tee -a $dest_file
$add_str1
$add_str2
$add_str3
EOL
fi

# Syslog
dest_file=/etc/rsyslog.conf
bak_file=`generate_backup_file_name $dest_file`
if ! grep -q "^#daemon\.\*"$'\t'".*$" $dest_file ; then
    sudo cp $dest_file $bak_file
    sudo sed -i \
        -e "s/^\(daemon\.\*"$'\t'".*$\)/#\1/" \
        -e "s/^\(kern\.\*"$'\t'".*$\)/#\1/" \
        -e "s/^\(lpr\.\*"$'\t'".*$\)/#\1/" \
        -e "s/^\(mail\.\*"$'\t'".*$\)/#\1/" \
        -e "s/^\(user\.\*"$'\t'".*$\)/#\1/" \
        -e "s/^\(mail\.info"$'\t'".*$\)/#\1/" \
        -e "s/^\(mail\.warn"$'\t'".*$\)/#\1/" \
        -e "s/^\(mail\.err"$'\t'".*$\)/#\1/" \
    $dest_file && \
    sudo sed -i -z -e \
        "s/\(\*\.=debug;\\\\\).*\("$'\t'"auth,authpriv.none;\\\\\).*\("$'\t'"mail\.none.*-\/var\/log\/debug\)/#\1\n#\2\n#\3/" \
    $dest_file
    diff_file $bak_file $dest_file
    sudo systemctl restart rsyslog
fi

# Use Power LED as heartbeat, disable WiFi, Disable BT
dest_file=/boot/firmware/config.txt
bak_file=`generate_backup_file_name $dest_file`
echo $bak_file
if ! grep -q "dtparam=pwr_led_trigger=heartbeat" $dest_file ; then
  sudo cp $dest_file $bak_file
  cat <<EOL | sudo tee -a $dest_file
[all]
# disable Wi-Fi
dtoverlay=disable-wifi
# disable BT
dtoverlay=disable-bt
# turn power LED into heartbeat
dtparam=pwr_led_trigger=heartbeat
EOL
  tail $dest_file
fi

# Remove some packages
sudo apt-get autoremove -y python3-pygame man manpages galculator

sudo reboot now