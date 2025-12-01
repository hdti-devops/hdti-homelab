# --- Kubernetes Master ---
resource "proxmox_vm_qemu" "k8s_master" {
  name        = var.k8s_master_name
  target_node = var.proxmox_node 
  clone       = var.vm_template_name 
  
  cpu {
    cores       = var.k8s_master_cores
    sockets     = var.k8s_master_sockets
  }
  
  memory      = var.k8s_master_memory
  scsihw      = "virtio-scsi-pci"
  
  # Cloud Init Settings
  os_type     = var.vm_os_type
  ipconfig0   = "ip=${var.k8s_master_ip}/24,gw=${var.default_gateway}" # Static IP
  nameserver  = var.technitium_dns 
  ciuser      = var.vm_user
  sshkeys     = file(var.ssh_public_key) # Your local SSH key
}

# --- Kubernetes Workers ---
resource "proxmox_vm_qemu" "k8s_workers" {
  count       = var.k8s_worker_count
  name        = "${var.k8s_worker_name_prefix}${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.vm_template_name
  
  cpu {
    cores       = var.k8s_master_cores
    sockets     = var.k8s_master_sockets
  }

  memory      = var.k8s_worker_memory
  scsihw      = "virtio-scsi-pci"
  
  os_type     = var.vm_os_type
  ipconfig0   = "ip=${var.k8s_worker_ip_prefix}${count.index + 1}/24,gw=${var.default_gateway}"
  nameserver  = var.technitium_dns
  ciuser      = var.vm_user
  sshkeys     = file(var.ssh_public_key)
}

# --- TrueNAS Scale VM ---
# Note: TrueNAS is easier to install via ISO than Cloud-Init template.
# This block creates the "Hardware" shell. You must mount ISO manually later.
resource "proxmox_vm_qemu" "truenas" {
  name        = var.truenas_name
  target_node = var.proxmox_node

  cpu {
    cores   = var.truenas_cores
    sockets = var.truenas_sockets
    type    = "host"    # Pass full CPU to VM (best for ZFS)
  }

  memory = var.truenas_memory
  balloon = 0            # MUST be disabled for ZFS

  scsihw = "virtio-scsi-pci"
  boot   = "order=ide2;scsi0"

  # ISO IN IDE2
  disks {
    ide {
      ide2 {
        cdrom {
          iso = var.truenas_iso
        }
      }
    }

    # MAIN STORAGE DISK (SCSI0)
    scsi {
      scsi0 {
        disk {
          size    = var.truenas_disk_size
          storage = var.vm_storage

          # Recommended ZFS settings
          cache      = "none"      # ZFS manages caching
          discard    = false       # Do NOT trim on ZFS boot disk
          emulatessd = true        # Optional: makes TrueNAS see SSD
        }
      }
    }
  }

  network {
    id       = 0
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  # Optional startup - Should it start when node is shuutdown the reboots
  start_at_node_boot = true

  # This tells Terraform to ignore changes to the disk configuration and boot order
  # after the VM is created. This allows you to unmount the ISO or pass through
  # physical disks manually without Terraform fighting you.
  lifecycle {
    ignore_changes = [
      disks,
      boot,
      qemu_os,
    ]
  }
}

# --- TrueNAS Scale VM ---
# Note: TrueNAS is easier to install via ISO than Cloud-Init template.
# This block creates the "Hardware" shell. You must mount ISO manually later.
# resource "proxmox_vm_qemu" "truenas" {
#   name        = var.truenas_name
#   target_node = var.proxmox_node
  
#   cores       = var.truenas_cores
#   sockets     = var.truenas_sockets
#   memory      = var.truenas_memory
#   # Add scsihw type here to match your other VMs (optional, but good practice)
#   scsihw          = "virtio-scsi-pci" 
  
#   # 1. THE STORAGE/BOOT DISK
#   disk {
#     # The 'slot' must specify the type (scsi) and ID (0)
#     slot            = "scsi0" 
#     type            = "disk"      # Explicitly setting type
#     size            = var.truenas_disk_size
#     storage         = var.vm_storage
#   }

#   # 2. THE ISO/CD-ROM DEVICE
#   disk {
#     slot            = "ide2"      # Attaches to IDE slot 2
#     type            = "cdrom"     # Explicitly setting type to cdrom
#     iso             = var.truenas_iso # The full storage path (local:iso/...)
#     storage         = "local"     # Must point to the storage where ISOs live
#   }
  
#   # Set boot order to prioritize the IDE CD-ROM (ide2) for installation
#   boot = "order=ide2;scsi0" 
  
#   network {
#     id     = 0
#     model  = "virtio"
#     bridge = "vmbr0"
#   }
# }