██████████████████████████████████████████████████████
██████████████████████████████████████████████████████
██████████████████████████████████████████████████████
█████████▀▄─██▄─▄▄▀█─▄▄▄─█─█─█─▄▄─█▄─▄▄─█▄─██─▄█─▄▄▄▄█
█████████─▀─███─▄─▄█─███▀█─▄─█─██─██─▄▄▄██─██─██▄▄▄▄─█
████████▄▄█▄▄█▄▄█▄▄█▄▄▄▄▄█▄█▄█▄▄▄▄█▄▄▄████▄▄▄▄██▄▄▄▄▄█

# nomis arch installer

- asus ux302l
- uefi, btrfs root, ext4 home, plasma, nvidia drivers
- 500GB SSD

## instructions

1. connection

- wire

or

- wifi :

```bash
iwctl
[iwctl] station wlan0 scan
[iwctl] station wlan0 connect <wifi-name>
[iwctl] exit 
```

2. install setup as root

```bash
chmod +x ./0_install_setup.sh
./0_install_setup.sh
```

3. install snapper for btrfs as root

```bash
chmod +x ./1_btrfs_snapper.sh
./1_btrfs_snapper.sh
```

4. install softwares as root

```bash
chmod +x ./2_softwares_install.sh
./2_softwares_install.sh
```

5. install softwares from aur as normal user

```bash
chmod +x ./3_softwares_install_aur.sh
./3_softwares_install_aur.sh
```

6. reboot

7. take first snapper snapshot

```bash
chmod +x ./4_take_first_snapper_snapshot.sh
./4_take_first_snapper_snapshot.sh
```

8. config

import dotfiles and files... 