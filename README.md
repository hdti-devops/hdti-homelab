# HDTI HOMELAB

I will be building a homelab with [Proxmox](https://www.proxmox.com/en/). On my homelab server, I will be installing:

* [Technitium DNS](https://technitium.com/dns/) as DNS server
* [Wireguard](https://www.wireguard.com/) as VPN
* [TrueNAS](https://www.truenas.com/truenas-community-edition/) as nas OS for managing data

I also will be building a kubernetes cluster with [kubeadmin](https://kubernetes.io/docs/reference/setup-tools/kubeadm/).</br>

## Table of content

- [Setup Proxmox](#setup-proxmox)
- [Setup Technitium (DNS Server)](#setup-technitium-dns-server)
- [Setup Wireguard (VPN)](#setup-wireguard-vpn)
- [Setup Cloudflare DDNS](#setup-cloudflare-ddns)
- [Setup Caddy](#setup-caddy)
- [Split-Horizon DNS with Let’s Encrypt + WireGuard VPN](#split-horizon-dns-combiened-with-letsencrypt-and-wireguard-vpn-setup)
- [IAC (Terraform)](#iac-terraform)
- [Kubernetes Cluster](#kubernetes-cluster)
  - [Get the cloud-image](#get-the-cloud-image)
  - [Create the base VM template](#create-an-empty-vm-container-to-hold-the-template)
  - [Register & attach disk + cloud-init](#register-image-to-the-proxmox-storage)
  - [Configure boot and convert to template](#set-boot-order-and-console)
  - [Alternative VM template setup](#new)
- [Terraform Code for the VMs](#terraform-code-for-the-vms)


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

[ x ] Pin Interfaces - Checked, Prevents future breakage

You can then complete the install and afterward remove the Bottable USB drive and restart your server. It will display the server's IP which you can then use with port 8006 to access the Proxmox's UI.

Proceeding to your first login, you will get a notification from Proxmox : No Valid Subscription for this server. Simply click ok. To disable this message on further logins, use the [Proxmox's Community helper scripts](https://community-scripts.github.io/ProxmoxVE/). The PVE post-install script will take care of removing this message disabling the enterprise repos and adding the free community repositories. It will also ask you if you want to make the available updates what I strongly suggest you do. After proceeding with the script, reebot your server. You can now see this annoying message has been removed.


## Setup Technitium (DNS Server)

Now, we will setup a DNS Server using Technitium. A [community script](https://community-scripts.github.io/ProxmoxVE/scripts?id=technitiumdns) is provided ffor this task and will create a Technitium LXC container for you. Once this script has finished you will have your first LXC container that will be running Technitium.</br>
When the LXC Container has started, you can login to your Technitium UI Dashboard at : <technitium's IP>:5380
</br></br>
You will then need to setup your admin credentials.</br>
After, go to the Settings tab and select  'Proxy & Forwarders'.

* Configure Forwarders (Google and CloudFlare)

```
Forwarders:
  dns.google (8.8.8.8:853)
  dns.google (8.8.4.4:853)
  cloudflare-dns.com (1.1.1.1:853)
  cloudflare-dns.com (1.0.0.1:853)

Forwarder Protocol:
  DNS-over-TLS || DNS-over-HTTPS

Concurrent Forwarding:
  enabled

Forwarder Concurrency:
  4
```

* Create a token

Go to the 'Administration' tab and click on 'create token'. 

```
User: admin
token_name: technitium
```

Store your token we will need it eventually for terraform.

## Setup Wireguard (VPN)

Now, we will setup our VPN with Wireguard. To install Wireguard in a LXC Container I will also use [the community helper script](https://community-scripts.github.io/ProxmoxVE/scripts?id=wireguard) with the default settings. When prompt to choose if you want to install the WireGuard Dashboard, choose yes to do so.</br>
Once the installation is finished, you can access your WireGuard dashboard <wireguard's IP>:10086. The default credentials are admin/admin. Change your credentials and setup/ or not the MFA.


# Setup cloudflare ddns

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/cloudflare-ddns.sh)"
```
API token cloudflare: dns edit

* advanced settings
* hostname: cloudflare-ddns
* dns server ip : technitium ip
* enable fuse: yes

Even though the Cloudflare DDNS script itself doesn't strictly require FUSE, enabling it is standard practice for almost all Linux containers and VMs in a home lab. It ensures the container has maximum compatibility for any future tools or modifications you might want to run, such as mounting remote file systems (rclone).

* domains: ddns.hdti.ca

```
The Dynamic A Record (DDNS Target)

First, create a dedicated, somewhat generic A record that the DDNS script will manage:
Record Type	Name	Target / Content	Proxy Status	DDNS Script Input
A	ddns	Your current Public IP	DNS Only (Gray Cloud)	ddns.hdti.ca

You would update your Cloudflare DDNS script to point to ddns.hdti.ca.
2. The CNAME Records (Your Services)

Next, in the Cloudflare DNS dashboard, create CNAME records for all your services. These records will simply alias, or point to, your dynamic ddns.hdti.ca record.
Record Type	Name	Target / Content	Proxy Status
CNAME	vpn	ddns.hdti.ca	DNS Only (Gray Cloud)
CNAME	pve	ddns.hdti.ca	Proxied (Orange Cloud)
CNAME	k8s	ddns.hdti.ca	Proxied (Orange Cloud)
```

* proxied: no

* Create the DDNS Target A Record

he DDNS script should handle this automatically, but log into Cloudflare and verify that the following A record exists:
Type	Name	Content (IP)	Proxy Status
A	ddns	(Your current public IP)	DNS Only (Gray)

* create cname record for vpn

Create the CNAME record for your VPN access:
Type	Name	Content	Proxy Status
CNAME	vpn	ddns.hdti.ca	DNS Only (Gray)

## Setup Caddy

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/caddy.sh)"
```

Advanced Install. Set ip to statis and your address /24, Gateway	192.168.0.1, dns -> technitium. DNS serach domain : main zone (hdti.lab). Would you like to install xCaddy Addon?  yes. xCaddy is the Caddy build tool. The Caddy Cloudflare DNS module is an external plugin and is not included in the standard Caddy package. To use the DNS-01 challenge, you need to use xCaddy to compile a custom Caddy binary that includes the Cloudflare plugin (github.com/caddy-dns/cloudflare)</br></br>

Next we will setup Caddy. You need to open the console for the container.
Because of this, the final Caddy binary is still the standard one, and it cannot perform the DNS-01 challenge for Let's Encrypt.
However, the good news is that all the required tools (Go, Git, xCaddy) are now installed inside your container! You just need to run the final custom build command manually.

```
# Run these commands inside the Caddy LXC (pct enter 107)

# 1. Stop the currently running Caddy service (which is the default, non-DNS-enabled one)
systemctl stop caddy

# 2. Use xcaddy to build a new Caddy executable that includes the Cloudflare DNS module
# This command replaces the default /usr/bin/caddy with the custom-built one.
/usr/bin/xcaddy build \
    --output /usr/bin/caddy \
    --with github.com/caddy-dns/cloudflare

# 3. Check the version (it should show the build flag, confirming the custom build)
caddy version
# The output should show the build configuration, often including the plugin path.
```

* Configure the Cloudflare API Token. Caddy needs your Cloudflare token to update the DNS records (TXT record challenge). The safest way is via a systemd environment variable.
* Edit the Caddy Systemd Service File: This creates an override file that persists through updates.

nano /etc/systemd/system/caddy.service.d/override.conf ((If this command fails, try sudo systemctl edit caddy.service)

```
Add the Environment Variable: Paste the following content, replacing the placeholder with your actual Cloudflare Global API Token (or a scoped API Token with Zone/DNS/Edit permissions for hdti.ca):
[Service]
Environment="CF_API_TOKEN=YOUR_CLOUDFLARE_API_TOKEN_HERE"
```

```
systemctl daemon-reload
```

* Configure the Caddyfile : you need to tell Caddy how to handle traffic for pve.hdti.ca

nano /etc/caddy/Caddyfile

```
pve.hdti.ca {
    # 1. Use the Cloudflare DNS module for the certificate challenge
    tls {
        dns cloudflare 

        # 2. Skip verification of Proxmox's self-signed certificate (internal trust)
        insecure_skip_verify 
    }

    # 3. Reverse Proxy to the Proxmox Host
    reverse_proxy 192.168.0.200:8006 {
        # Required headers for proper Proxmox websocket/console function
        header_up Host {host}
        header_up X-Forwarded-Proto https
    }
}
```

```
systemctl start caddy
```

* Monitor Logs for Certificate Success: This is the most crucial step. Watch the output to see if the certificate is successfully acquired.

```
journalctl -u caddy -f
```

## Split-Horizon DNS combiened with LetsEncrypt and WireGuard VPN setup.

I will use this method that resolves the "Unsafe" warning without creating your own internal CA.

* By using Let's Encrypt, the certificate is globally trusted by all browsers, eliminating warnings.
* You do not need to open port 80 or 443 on your firewall, ensuring the Proxmox UI remains inaccessible to the public internet.
* The DDNS script keeps the public record pointing to the correct address for the certificate renewal process.
* You only access Proxmox via your WireGuard VPN, which provides the necessary network access.

Configure Internal DNS (Technitium Override): Navigate to your hdti.lab Zone (or create a Local Zone for hdti.ca if needed)., add new A record: A	pve.hdti.ca	192.168.0.200





## IAC (Terraform)

We will now continue using Terraform to setup our base infrastructure for our VMs for our Kubernetes Cluster and for TrueNAS.


## Kubernetes Cluster

### Get the cloud-image

```wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img```

### Create an empty VM container to hold the template

```qm create 9000 --name "ubuntu-2404-template" --memory 2048 --net0 virtio,bridge=vmbr0```

### Register image to the Proxmox storage

```qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm```

### Attatch the disk and add Cloud-Init drive

```
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0 \
qm set 9000 --ide2 local-lvm:cloudinit
```

# Set boot order and console

```
qm set 9000 --boot c --bootdisk scsi0 \
```

### Convert the VM into a Reusable Template

```qm template 9000```


### NEW
qm create 9005 --name "ubuntu-2404-cgpt" --memory 2048 --net0 virtio,bridge=vmbr0 
qm set 9005 --bios ovmf 
qm set 9005 --machine q35 
qm set 9005 --efidisk0 local-lvm:1 
qm importdisk 9005 noble-server-cloudimg-amd64.img local-lvm
qm config 9005
qm set 9005 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9005-disk-1
qm set 9005 --ide2 local-lvm:cloudinit
qm set 9005 --boot order=scsi0
qm template 9005

Once the last command (qm template 9000) runs, you will see the ubuntu-2404-template (9000) listed under your Proxmox node in the UI.
scp ./vm-template.sh root@192.168.0.200:/root/
## Terraform code for the VMs

Create a Terraform user in the Proxmox Web UI. 

```Datacenter -> Permissions -> Users```

Click 'add':</br>
name: terraform</br>
realm: Linux PAM</br></br>

Assign Permissions:</br>
```Datacenter -> Permissions -> API Tokens```



```
export TF_VAR_pm_api_token_secret="YOUR_LONG_TOKEN_SECRET_FROM_PROXMOX"
```
82fdcf48-d405-42b0-bb56-f0422c0bf0f0

edit C:\Users\Dom\.ssh\known_hosts