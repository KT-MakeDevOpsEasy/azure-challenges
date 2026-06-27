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

  acr_name = "acr${var.project}${var.environment}${local.short_location}"

  common_tags = {
    Environment   = var.environment
    Project       = var.project
    ApplicationId = var.application_id
    ManagedBy     = "terraform"
    Region        = var.location
  }
}
