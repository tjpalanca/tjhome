terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.0.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
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
  keycloak_url = "https://${var.keycloak_subdomain}.${var.main_cloudflare_zone_name}"
}

resource "keycloak_realm" "main" {
  realm             = "tjhome"
  display_name      = "TJHome"
  display_name_html = "<div class='logo-text'><img style='max-height: 120px;' src='https://tjpalanca.com/assets/logo/logo-small.png'></div>"
  login_theme       = "social"
}

module "code_port_gateway" {
  source    = "github.com/tjpalanca/tjcloud//elements/gateway"
  host      = "home"
  zone_id   = var.main_cloudflare_zone_id
  zone_name = var.main_cloudflare_zone_name
  service = {
    name      = "code"
    port      = 8889
    namespace = "code"
  }
  keycloak_realm_id = "tjcloud"
  keycloak_url      = local.keycloak_url
}
