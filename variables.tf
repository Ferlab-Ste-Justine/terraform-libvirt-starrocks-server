variable "name" {
  description = "Name to give to the vm"
  type        = string
}

variable "hostname" {
  description = "Value to assign to the hostname. If left to empty (default), 'name' variable will be used."
  type        = object({
    hostname = string
    is_fqdn  = string
  })
  default = {
    hostname = ""
    is_fqdn  = false
  }
}

variable "vcpus" {
  description = "Number of vcpus to assign to the vm"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Amount of memory in MiB"
  type        = number
  default     = 512
}

variable "volume_id" {
  description = "Id of the disk volume to attach to the vm"
  type        = string
}

variable "libvirt_networks" {
  description = "Parameters of libvirt network connections if libvirt networks are used"
  type = list(object({
    network_name = optional(string, "")
    network_id = optional(string, "")
    prefix_length = string
    ip = string
    mac = string
    gateway = optional(string, "")
    dns_servers = optional(list(string), [])
  }))
  default = []
}

variable "macvtap_interfaces" {
  description = "List of macvtap interfaces"
  type        = list(object({
    interface     = string
    prefix_length = string
    ip            = string
    mac           = string
    gateway       = optional(string, "")
    dns_servers   = optional(list(string), [])
  }))
  default = []
}

variable "cloud_init_volume_pool" {
  description = "Name of the volume pool that will contain the cloud init volume"
  type        = string
}

variable "cloud_init_volume_name" {
  description = "Name of the cloud init volume"
  type        = string
  default     = ""
}

variable "ssh_admin_user" { 
  description = "Pre-existing ssh admin user of the image"
  type        = string
  default     = "ubuntu"
}

variable "admin_user_password" { 
  description = "Optional password for admin user"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_admin_public_key" {
  description = "Public ssh part of the ssh key the admin will be able to login as"
  type        = string
}

variable "chrony" {
  description = "Chrony configuration for ntp. If enabled, chrony is installed and configured, else the default image ntp settings are kept"
  type        = object({
    enabled = bool,
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#server
    servers = list(object({
      url     = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#pool
    pools = list(object({
      url     = string,
      options = list(string)
    })),
    //https://chrony.tuxfamily.org/doc/4.2/chrony.conf.html#makestep
    makestep = object({
      threshold = number,
      limit     = number
    })
  })
  default = {
    enabled  = false
    servers  = []
    pools    = []
    makestep = {
      threshold  = 0,
      limit      = 0
    }
  }
}

variable "fluentbit" {
  description = "Fluent-bit configuration"
  sensitive = true
  type = object({
    enabled = bool
    starrocks_tag = string
    node_exporter_tag = string
    starrocks_node_log_tag = string
    metrics = optional(object({
      enabled = bool
      port    = number
    }), {
      enabled = false
      port = 0
    })
    forward = object({
      domain = string
      port = number
      hostname = string
      shared_key = string
      ca_cert = string
    })
  })
  default = {
    enabled = false
    starrocks_tag = ""
    node_exporter_tag = ""
    starrocks_node_log_tag = ""
    metrics = {
      enabled = false
      port = 0
    }
    forward = {
      domain = ""
      port = 0
      hostname = ""
      shared_key = ""
      ca_cert = ""
    }
  }
}

variable "fluentbit_dynamic_config" {
  description = "Parameters for fluent-bit dynamic config if it is enabled"
  type = object({
    enabled = bool
    source  = string
    etcd    = optional(object({
      key_prefix     = string
      endpoints      = list(string)
      ca_certificate = string
      client         = object({
        certificate = string
        key         = string
        username    = string
        password    = string
      })
    }), {
      key_prefix     = ""
      endpoints      = []
      ca_certificate = ""
      client         = {
        certificate = ""
        key         = ""
        username    = ""
        password    = ""
      }
    })
    git     = optional(object({
      repo             = string
      ref              = string
      path             = string
      trusted_gpg_keys = list(string)
      auth             = object({
        client_ssh_key         = string
        client_ssh_user        = string
        server_ssh_fingerprint = string
      })
    }), {
      repo             = ""
      ref              = ""
      path             = ""
      trusted_gpg_keys = []
      auth             = {
        client_ssh_key         = ""
        client_ssh_user        = ""
        server_ssh_fingerprint = ""
      }
    })
  })
  default = {
    enabled = false
    source = "etcd"
    etcd = {
      key_prefix     = ""
      endpoints      = []
      ca_certificate = ""
      client         = {
        certificate = ""
        key         = ""
        username    = ""
        password    = ""
      }
    }
    git  = {
      repo             = ""
      ref              = ""
      path             = ""
      trusted_gpg_keys = []
      auth             = {
        client_ssh_key         = ""
        client_ssh_user        = ""
        server_ssh_fingerprint = ""
      }
    }
  }

  validation {
    condition     = contains(["etcd", "git"], var.fluentbit_dynamic_config.source)
    error_message = "fluentbit_dynamic_config.source must be 'etcd' or 'git'."
  }
}

variable "install_dependencies" {
  description = "Whether to install all dependencies in cloud-init"
  type        = bool
  default     = true
}

variable "timezone" {
  description = "Timezone"
  type        = string
  default     = "America/Montreal"
}

variable "starrocks" {
  description = "Configuration for the starrocks server"
  type        = object({
    release_version = optional(string, "3.4.1"),
    node_type       = string
    fe_config       = optional(object({
      initial_leader = optional(object({
        enabled           = bool
        fe_follower_fqdns = list(string)
        be_fqdns          = list(string)
        root_password     = string
        users             = optional(list(object({
          name         = string
          password     = string
          default_role = optional(string, "public")
        })), []),
      }), {
        enabled           = false
        fe_follower_fqdns = []
        be_fqdns          = []
        root_password     = ""
        users             = []
      })
      initial_follower = optional(object({
        enabled        = bool
        fe_leader_fqdn = string
      }), {
        enabled        = false
        fe_leader_fqdn = ""
      })
      ssl = optional(object({
        enabled           = bool
        cert              = string
        key               = string
        keystore_password = string
      }), {
        enabled           = false
        cert              = ""
        key               = ""
        keystore_password = ""
      })
      iceberg_rest = optional(object({
        ca_cert  = string
        env_name = string
      }), {
        ca_cert  = ""
        env_name = ""
      })
    }), {
      initial_leader   = null
      initial_follower = null
      ssl              = null
      iceberg_rest     = null
    })
  })

  validation {
    condition     = contains(["fe", "be"], var.starrocks.node_type)
    error_message = "starrocks.node_type must be 'fe' or 'be'."
  }

  validation {
    condition = (
      var.starrocks.node_type == "be" ||
      (
        var.starrocks.node_type == "fe" &&
        var.starrocks.fe_config != null &&
        (
          (try(var.starrocks.fe_config.initial_leader.enabled, false) && !try(var.starrocks.fe_config.initial_follower.enabled, false)) ||
          (!try(var.starrocks.fe_config.initial_leader.enabled, false) && try(var.starrocks.fe_config.initial_follower.enabled, false))
        )
      )
    )
    error_message = "When starrocks.node_type is 'fe', starrocks.fe_config must be provided with either initial_leader.enabled or initial_follower.enabled set to true."
  }
}
