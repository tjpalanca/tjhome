terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.0.1"
    }
  }
  cloud {
    organization = "tjpalanca"
    workspaces {
      name = "tjhome"
    }
  }
}

locals {
  keycloak_url   = "https://${var.keycloak_subdomain}.${var.main_cloudflare_zone_name}"
  keycloak_realm = "tjcloud"
  subdomain      = "google"
  domain         = "${local.subdomain}.${var.main_cloudflare_zone_name}"
}

resource "keycloak_openid_client" "client" {
  realm_id              = "tjcloud"
  client_id             = local.domain
  name                  = local.domain
  enabled               = true
  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  valid_redirect_uris = [
    "https://${local.domain}/oauth2/callback"
  ]
}
