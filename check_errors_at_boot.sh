sudo systemctl --failed
sudo journalctl -p 3 -xb
sudo journalctl -p 4 -xb
sudo dmesg | grep fail
sudo dmesg | grep error
sudo dmesg | grep err
