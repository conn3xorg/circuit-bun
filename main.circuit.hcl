# Facts give each host's architecture, which picks the release zip.
data "conn3x_host" "facts" {
  for_each = var.hosts

  ssh {
    host             = try(each.value.address, each.value)
    host_key         = try(each.value.host_key, null)
    user             = try(each.value.user, var.ssh_user)
    port             = try(each.value.port, var.ssh_port)
    private_key_file = try(each.value.private_key_file, var.ssh_private_key_file)
    jump_hosts       = try(each.value.jump_hosts, null)
    known_hosts_file = var.ssh_known_hosts_file
  }

  lifecycle {
    postcondition {
      condition     = contains(keys(local.bun_arch), self.arch)
      error_message = "Host ${each.key} is ${self.arch}. This circuit installs the linux-x64 and linux-aarch64 builds."
    }
  }
}

locals {
  bun_arch = { x86_64 = "x64", aarch64 = "aarch64" }
  arch     = { for name in keys(var.hosts) : name => lookup(local.bun_arch, data.conn3x_host.facts[name].arch, data.conn3x_host.facts[name].arch) }
  release  = "/opt/bun/${var.bun_version}"
  home     = { for name, a in local.arch : name => "${local.release}/bun-linux-${a}" }
}

circuit "bun" {
  hosts = var.hosts

  ssh {
    user             = var.ssh_user
    port             = var.ssh_port
    private_key_file = var.ssh_private_key_file
    known_hosts_file = var.ssh_known_hosts_file
    become           = var.ssh_become
  }

  step "tool" {
    for_each = ["curl", "unzip"]
    package {
      name = item.value
    }
  }

  # The download step keeps the zip only if it matches the checksum, which
  # comes from the release's SHASUMS256.txt.
  step "download" {
    download {
      url    = "https://github.com/oven-sh/bun/releases/download/bun-v${var.bun_version}/bun-linux-${local.arch[each.key]}.zip"
      sha256 = var.checksums[local.arch[each.key]]
      dest   = "${local.release}/bun-linux-${local.arch[each.key]}.zip"
    }
  }

  step "unpack" {
    archive {
      src     = "${local.release}/bun-linux-${local.arch[each.key]}.zip"
      dest    = local.release
      creates = "${local.home[each.key]}/bun"
    }
  }

  # The zip holds only bun. The bunx command is bun under a second name,
  # which is how upstream's installer sets it up too.
  step "link" {
    for_each = ["bun", "bunx"]
    link {
      path   = "/usr/local/bin/${item.value}"
      target = "${local.home[each.key]}/bun"
    }
  }

  # An x64 CPU without SSE4.2 passes every step above and then can't run
  # the binary, so the apply says so here rather than leaving a broken bun.
  step "runs" {
    command {
      command  = "[ \"$(/usr/local/bin/bun --version)\" = '${var.bun_version}' ]"
      triggers = { version = var.bun_version }
    }
  }
}
