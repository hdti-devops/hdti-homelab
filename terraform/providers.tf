terraform {

  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.2-rc06"
    }

  }

}

provider "proxmox" {
  pm_api_url = "https://${var.proxmox_host}:8006/api2/json"
  pm_api_token_id = "terraform@pam!terraform_token"
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure = true
}