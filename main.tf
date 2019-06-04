provider "azurerm" {
  version = "~> 1.28.0"
}

locals {
  tags = {
    "managed"     = "terraformed"
    "owner"       = "me@me.me"
    "environment" = "learning"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "MyDB-RG"
  location = "West Europe"
  tags     = "${local.tags}"
}

######################################################################
resource "azurerm_virtual_network" "main" {
  name                = "production-network"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  address_space       = ["10.0.0.0/16"]
  tags                = "${local.tags}"
}
################database#####

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "tfex-cosmos-db-${random_integer.ri.result}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = true

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = "East US"
    failover_priority = 1
  }

  geo_location {
    prefix            = "tfex-cosmos-db-${random_integer.ri.result}-customid"
    location          = "${azurerm_resource_group.main.location}"
    failover_priority = 0
  }
}
###############################################################
resource "azurerm_app_service_plan" "main" {
  name                = "Dev-appserviceplan"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  tags                = "${local.tags}"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "main" {
  name                = "iDare-Dev-app-service"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  app_service_plan_id = "${azurerm_app_service_plan.main.id}"
  tags                = "${local.tags}"

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "Name" = "Dev"
  }

  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=Dev.mydomain.com;Integrated Security=SSPI"
  }
}
##################################################################
resource "azurerm_sql_server" "main" {
  name                         = "mytfqlserver"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  location                     = "${azurerm_resource_group.main.location}"
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
  tags                         = "${local.tags}"
}

resource "azurerm_sql_firewall_rule" "main" {
  name                = "AlllowAzureServices"
  resource_group_name = "${azurerm_resource_group.main.name}"
  server_name         = "${azurerm_sql_server.main.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_database" "main" {
  name                             = "mysqldatabase"
  resource_group_name              = "${azurerm_resource_group.main.name}"
  location                         = "${azurerm_resource_group.main.location}"
  server_name                      = "${azurerm_sql_server.main.name}"
  edition                          = "Standard"
  requested_service_objective_name = "S1"
  tags                             = "${local.tags}"
}
