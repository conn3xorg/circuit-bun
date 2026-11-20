variable "hosts" {
  type        = any
  description = "Hosts to configure: a map of names to addresses, or to host objects with an address and optional host_key, user, port, private_key_file or jump_hosts."
}

variable "ssh_user" {
  type        = string
  default     = "root"
  description = "User to log in as."
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "SSH port."
}

variable "ssh_private_key_file" {
  type        = string
  default     = null
  description = "Path to a private key. When null, Conn3x uses the SSH agent."
}

variable "ssh_known_hosts_file" {
  type        = string
  default     = null
  description = "known_hosts file to check host keys against. When null, ~/.ssh/known_hosts."
}

variable "ssh_become" {
  type        = bool
  default     = false
  description = "Run commands as root through sudo."
}

variable "bun_version" {
  type        = string
  default     = "1.4.5"
  description = "Bun release to install, such as \"1.4.5\". Change checksums with it."

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.bun_version))
    error_message = "bun_version must look like \"1.4.5\", without a leading v."
  }
}

variable "checksums" {
  type        = map(string)
  description = "SHA-256 of the bun-linux-x64.zip and bun-linux-aarch64.zip files, from the release's SHASUMS256.txt. Change these with bun_version."
  default = {
    x64     = "94559b3b528995a49452f9f2404cec74f2efd7d06e0a000a8cd214b02c3666eb"
    aarch64 = "18656a3bf0ea5641f5796ae4213b75255579a70a0fded2f337933785568cdf84"
  }

  validation {
    condition     = alltrue([for c in values(var.checksums) : can(regex("^[0-9a-f]{64}$", c))])
    error_message = "Each of checksums must be a SHA-256 in lowercase hex."
  }
}
