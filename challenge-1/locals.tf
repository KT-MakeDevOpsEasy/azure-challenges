locals {
  location_short_map = {
    eastus      = "eus"
    eastus2     = "eus2"
    westus2     = "wus2"
    westeurope  = "weu"
    northeurope = "neu"
    centralus   = "cus"
  }

  short_location = lookup(local.location_short_map, var.location, substr(var.location, 0, 4))
  name_suffix    = "${var.project}-${var.environment}-${local.short_location}"

  common_tags = {
    Environment   = var.environment
    Project       = var.project
    ApplicationId = var.application_id
    ManagedBy     = "terraform"
    Region        = var.location
  }

  base_nsg_rules = {
    compute = [
      {
        name                       = "AllowSSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = var.ssh_source_prefix
        destination_address_prefix = "*"
      },
    ]
    storage = []
  }

  nsg_rules = {
    for key, rules in local.base_nsg_rules :
    key => concat(rules, lookup(var.extra_nsg_rules, key, []))
  }
}
