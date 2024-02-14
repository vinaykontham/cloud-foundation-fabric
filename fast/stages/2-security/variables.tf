/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    outputs_bucket = string
  })
}

variable "billing_account" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id. If billing account is not part of the same org set `is_org_level` to false."
  type = object({
    id           = string
    is_org_level = optional(bool, true)
  })
  validation {
    condition     = var.billing_account.is_org_level != null
    error_message = "Invalid `null` value for `billing_account.is_org_level`."
  }
}

variable "essential_contacts" {
  description = "Email used for essential contacts, unset if null."
  type        = string
  default     = null
}

variable "folder_ids" {
  # tfdoc:variable:source 1-resman
  description = "Folder name => id mappings, the 'security' folder name must exist."
  type = object({
    security = string
  })
}

variable "kms_keys" {
  description = "KMS keys to create, keyed by name."
  type = map(object({
    rotation_period               = optional(string, "7776000s")
    labels                        = optional(map(string))
    locations                     = optional(list(string), ["europe", "europe-west1", "europe-west3", "global"])
    purpose                       = optional(string, "ENCRYPT_DECRYPT")
    skip_initial_version_creation = optional(bool, false)
    version_template = optional(object({
      algorithm        = string
      protection_level = optional(string, "SOFTWARE")
    }))

    iam = optional(map(list(string)), {})
    iam_bindings = optional(map(object({
      members = list(string)
      role    = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
    iam_bindings_additive = optional(map(object({
      member = string
      role   = string
      condition = optional(object({
        expression  = string
        title       = string
        description = optional(string)
      }))
    })), {})
  }))
  default  = {}
  nullable = false
}

variable "organization" {
  # tfdoc:variable:source 0-bootstrap
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "prefix" {
  # tfdoc:variable:source 0-bootstrap
  description = "Prefix used for resources that need unique names. Use 9 characters or less."
  type        = string

  validation {
    condition     = try(length(var.prefix), 0) < 10
    error_message = "Use a maximum of 9 characters for prefix."
  }
}

variable "service_accounts" {
  # tfdoc:variable:source 1-resman
  description = "Automation service accounts that can assign the encrypt/decrypt roles on keys."
  type = object({
    data-platform-dev    = string
    data-platform-prod   = string
    project-factory-dev  = string
    project-factory-prod = string
  })
}

variable "vpc_sc_access_levels" {
  description = "VPC SC access level definitions."
  type = map(object({
    combining_function = optional(string)
    conditions = optional(list(object({
      device_policy = optional(object({
        allowed_device_management_levels = optional(list(string))
        allowed_encryption_statuses      = optional(list(string))
        require_admin_approval           = bool
        require_corp_owned               = bool
        require_screen_lock              = optional(bool)
        os_constraints = optional(list(object({
          os_type                    = string
          minimum_version            = optional(string)
          require_verified_chrome_os = optional(bool)
        })))
      }))
      ip_subnetworks         = optional(list(string), [])
      members                = optional(list(string), [])
      negate                 = optional(bool)
      regions                = optional(list(string), [])
      required_access_levels = optional(list(string), [])
    })), [])
    description = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "vpc_sc_egress_policies" {
  description = "VPC SC egress policy definitions."
  type = map(object({
    from = object({
      identity_type = optional(string, "ANY_IDENTITY")
      identities    = optional(list(string))
    })
    to = object({
      operations = optional(list(object({
        method_selectors = optional(list(string))
        service_name     = string
      })), [])
      resources              = optional(list(string))
      resource_type_external = optional(bool, false)
    })
  }))
  default  = {}
  nullable = false
}

variable "vpc_sc_ingress_policies" {
  description = "VPC SC ingress policy definitions."
  type = map(object({
    from = object({
      access_levels = optional(list(string), [])
      identity_type = optional(string)
      identities    = optional(list(string))
      resources     = optional(list(string), [])
    })
    to = object({
      operations = optional(list(object({
        method_selectors = optional(list(string))
        service_name     = string
      })), [])
      resources = optional(list(string))
    })
  }))
  default  = {}
  nullable = false
}

variable "vpc_sc_perimeters" {
  description = "VPC SC regular perimeter definitions."
  type = object({
    dev = optional(object({
      access_levels    = optional(list(string), [])
      egress_policies  = optional(list(string), [])
      ingress_policies = optional(list(string), [])
      resources        = optional(list(string), [])
    }), {})
    landing = optional(object({
      access_levels    = optional(list(string), [])
      egress_policies  = optional(list(string), [])
      ingress_policies = optional(list(string), [])
      resources        = optional(list(string), [])
    }), {})
    prod = optional(object({
      access_levels    = optional(list(string), [])
      egress_policies  = optional(list(string), [])
      ingress_policies = optional(list(string), [])
      resources        = optional(list(string), [])
    }), {})
  })
  default  = {}
  nullable = false
}
