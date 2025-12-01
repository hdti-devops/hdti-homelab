# HDTI HOMELAB

I will be building a homelab with [Proxmox](https://www.proxmox.com/en/). On my homelab server, I will be installing:

* [Technitium DNS](https://technitium.com/dns/) as DNS server
* [Wireguard](https://www.wireguard.com/) as VPN
* [TrueNAS](https://www.truenas.com/truenas-community-edition/) as nas OS for managing data

I also will be building a kubernetes cluster with [kubeadmin](https://kubernetes.io/docs/reference/setup-tools/kubeadm/).</br>

## Setup Proxmox

* Download Proxmox VE ISO Installer image fom [the official site](https://www.proxmox.com/en/downloads).
* Make a bootable USB drive with the image, here i used [Rufus](https://rufus.ie/en/).
* Plug the Bootable USB to your server and set USB as first boot option in the BIOS.
* Proceed with the GUI Install

| Field             | Value           | Explanation                                         |
|-------------------|------------------|-------------------------------------------------------------------------------|
| Hostname (FQDN)   | pve.homelab      | Fully-qualified domain name for the Proxmox server. Can go with wtv suits you.|
| IP Address (CIDR) | 192.168.1.50/24  | Static IP address with subnet mask in CIDR format. Must be static and free.   |
| Gateway           | 192.168.1.1      | Router or network gateway used for outbound traffic. Here your router's IP.   |
| DNS Server        | 1.1.1.1          | DNS resolver for domain name lookups. Put 8.8.8.8 or 1.1.1.1                  |

[x] Pin Interfaces - Checked, Prevents future breakage

You can then complete the install and afterward remove the Bottable USB drive and restart your server. It will display the server's IP which you can then use with port 8006 to access the Proxmox's UI.

Proceeding to your first login, you will get a notification from Proxmox : No Valid Subscription for this server. Simply click ok. To disable this message on further logins, use the [Proxmox's Community helper scripts](https://community-scripts.github.io/ProxmoxVE/). The PVE post-install script will take care of removing this message disabling the enterprise repos and adding the free community repositories. It will also ask you if you want to make the available updates what I strongly suggest you do. After proceeding with the script, reebot your server. You can now see this annoying message has been removed.

## Setup Technitium (DNS Server)

Now, we will setup a DNS Server using Technitium. A [community script](https://community-scripts.github.io/ProxmoxVE/scripts?id=technitiumdns) is provided ffor this task and will create a Technitium LXC container for you. Once this script has finished you will have your first LXC container that will be running Technitium.</br>
When the LXC Container has started, you can login to your Technitium UI Dashboard at : <technitium's IP>:5380
</br></br>
You will then need to setup your admin credentials. After, go to the Settings tab and select  'Proxy & Forwarders'.



## Setup Wireguard (VPN)

Now, we will setup our VPN with Wireguard. To install Wireguard in a LXC Container I will also use [the community helper script](https://community-scripts.github.io/ProxmoxVE/scripts?id=wireguard) with the default settings. When prompt to choose if you want to install the WireGuard Dashboard, choose yes to do so.</br>
Once the installation is finished, you can access your WireGuard dashboard <wireguard's IP>:10086. The default credentials are admin/admin. Change your credentials and setup/ or not the MFA.


## Kubernetes Cluster