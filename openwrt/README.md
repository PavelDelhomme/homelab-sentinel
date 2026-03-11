# Configs OpenWrt pour Pi 2 routeur

À utiliser **quand tu auras un dongle USB-Ethernet**. Sans dongle, la Pi ne peut pas faire WAN + LAN en même temps (un seul port Ethernet natif).

- **eth0** : port Ethernet natif de la Pi → LAN (vers switch / clients).
- **eth1** : dongle USB-Ethernet → WAN (vers la box).

## Driver USB-Ethernet

Selon le **chipset** du dongle, installer sur la Pi (OpenWrt) :

```bash
opkg update
# TP-Link UE300 et similaires (RTL8153) :
opkg install kmod-usb-net-rtl8152
# Autres (AX88179) :
# opkg install kmod-usb-net-asix-ax88179
reboot
```

Pour identifier le chipset : brancher le dongle et faire `dmesg | grep -i usb` ou `lsusb`.

## Fichiers

- `network.example.conf` — à copier vers `/etc/config/network` sur la Pi (adapter `option device` pour WAN/LAN).
- `nftables.example.conf` — exemple de règles firewall (à intégrer via LuCI ou `/etc/nftables.conf`).

Référence complète : [guide_domotique_complet.md](../guide_domotique_complet.md) section 1.
