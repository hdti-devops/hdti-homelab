# --- Global Proxmox Settings ---
variable "proxmox_host" {
  description = "The IP address of your Proxmox host."
  type        = string
  default     = "192.168.0.200" # Your Proxmox Host IP
}

variable "proxmox_node" {
  description = "The name of your Proxmox node (e.g., pve)."
  type        = string
  default     = "pve" # Your proxmox node name
}

variable "vm_storage" {
  description = "The LVM-Thin storage pool for VM disks."
  type        = string
  default     = "local-lvm" # Location of your VM disks
}

variable "template_name" {
  description = "The name of the Cloud-Init template."
  type        = string
  default     = "ubuntu-2404-template" # Template ID 9000
}

variable "pm_api_token_secret" {
  description = "The secret part of the Proxmox API token."
  type        = string
  sensitive   = true # Marks the variable as sensitive to hide it in logs/output
}

# --- Cloud-Init & Access Settings ---
variable "vm_user" {
  description = "The SSH user for the new VMs."
  type        = string
  default     = "adminuser"
}

variable "ssh_public_key" {
  description = "Path to your local public SSH key file."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# --- Network Settings (Crucial IP Range) ---
variable "network_subnet" {
  description = "The CIDR subnet for your home network."
  type        = string
  default     = "192.168.0.0/24" # Your Verified Home Subnet
}

variable "default_gateway" {
  description = "The default gateway (router IP)."
  type        = string
  default     = "192.168.0.1" # Your Router IP
}

variable "technitium_dns" {
  description = "The IP address of your Technitium DNS LXC."
  type        = string
  default     = "192.168.0.184" # Your Technitium IP
}

# --- VM Settings ---
variable "vm_template_name" {
  description = "Name of the template to use for all VMs."
  type        = string
  default     = "ubuntu-2404-template" # The template ID 9000 we made
}

variable "vm_os_type" {
  description = "Type of os for all VMs."
  type        = string
  default     = "cloud-init"
}

# --- Kubernetes Master ---
variable "k8s_master_name" {
  description = "Name of the Kubernetes Master VM."
  type        = string
  default     = "k8s-master-01"
}

variable "k8s_master_cores" {
  description = "Number of cores for the Kubernetes Master VM."
  type        = number
  default     = 1
}

variable "k8s_master_sockets" {
  description = "Number of sockets for the Kubernetes Master VM."
  type        = number
  default     = 2
}

variable "k8s_master_memory" {
  description = "RAM for the Kubernetes Master VM."
  type        = number
  default     = 2048
}

variable "k8s_master_ip" {
  description = "IP for the Kubernetes Master VM."
  type        = string
  default     = "192.168.0.50"
}

# --- Kubernetes Workers ---
variable "k8s_worker_count" {
  description = "Number of desired kubernetes workers."
  type        = number
  default     = 2
}

variable "k8s_worker_name_prefix" {
  description = "Prefix for the names of the Kubernetes Worker VMs."
  type        = string
  default     = "k8s-worker-"
}

variable "k8s_worker_cores" {
  description = "Number of cores for the Kubernetes Master VM."
  type        = number
  default     = 1
}

variable "k8s_worker_sockets" {
  description = "Number of sockets for the Kubernetes Master VM."
  type        = number
  default     = 2
}

variable "k8s_worker_memory" {
  description = "RAM for the Kubernetes Master VM."
  type        = number
  default     = 4096
}

variable "k8s_worker_ip_prefix" {
  description = "Prefix for the IPs of the Kubernetes Worker VMs."
  type        = string
  default     = "192.168.0.5"
}

# --- TrueNAS VM Settings ---
variable "truenas_name" {
  description = "Name of the trueNAS VM."
  type        = string
  default     = "truenas-core"
}

variable "truenas_cores" {
  description = "Number of cores for the Kubernetes Master VM."
  type        = number
  default     = 1
}

variable "truenas_sockets" {
  description = "Number of sockets for the Kubernetes Master VM."
  type        = number
  default     = 2
}

variable "truenas_memory" {
  description = "RAM for the Kubernetes Master VM."
  type        = number
  default     = 8192
}

variable "truenas_disk_size" {
  description = "Disk Size for the TrueNAS VM."
  type        = string
  default     = "32G"
}

variable "truenas_iso" {
  description = "The trueNAS iso file."
  type        = string
  default     = "local:iso/TrueNAS-SCALE-25.10.0.1.iso" # Upload ISO to Proxmox first
}