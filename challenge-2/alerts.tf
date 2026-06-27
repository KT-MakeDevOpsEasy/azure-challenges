resource "azurerm_monitor_action_group" "aks" {
  count = var.enable_alerts ? 1 : 0

  name                = "ag-aks-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "aks-alerts"
  tags                = local.common_tags

  email_receiver {
    name          = "ops-team"
    email_address = var.alert_email
  }
}

# --- Node CPU Alerts ---

resource "azurerm_monitor_metric_alert" "node_cpu_warning" {
  count = var.enable_alerts ? 1 : 0

  name                = "alert-cpu-warning-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [module.aks.cluster_id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 70
  }

  action {
    action_group_id = azurerm_monitor_action_group.aks[0].id
  }
}

resource "azurerm_monitor_metric_alert" "node_cpu_critical" {
  count = var.enable_alerts ? 1 : 0

  name                = "alert-cpu-critical-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [module.aks.cluster_id]
  severity            = 0
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.aks[0].id
  }
}

# --- Node Memory Alerts ---

resource "azurerm_monitor_metric_alert" "node_memory_warning" {
  count = var.enable_alerts ? 1 : 0

  name                = "alert-mem-warning-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [module.aks.cluster_id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 75
  }

  action {
    action_group_id = azurerm_monitor_action_group.aks[0].id
  }
}

resource "azurerm_monitor_metric_alert" "node_memory_critical" {
  count = var.enable_alerts ? 1 : 0

  name                = "alert-mem-critical-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [module.aks.cluster_id]
  severity            = 0
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.aks[0].id
  }
}

# --- Pod Health Alert ---

resource "azurerm_monitor_metric_alert" "pod_failed" {
  count = var.enable_alerts ? 1 : 0

  name                = "alert-pod-failed-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [module.aks.cluster_id]
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "kube_pod_status_phase"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      name     = "phase"
      operator = "Include"
      values   = ["Failed"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.aks[0].id
  }
}
