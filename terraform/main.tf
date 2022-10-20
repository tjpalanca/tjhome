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
  port         = 3838
}

resource "keycloak_realm" "tjhome" {
  realm             = "tjhome"
  display_name      = "TJHome"
  display_name_html = "<div class='logo-text'><img style='max-height: 120px;' src='https://tjpalanca.com/assets/logo/logo-small.png'></div>"
  login_theme       = "social"
}

resource "kubernetes_service_v1" "tjhome" {
  metadata {
    name      = "tjhome"
    namespace = "code"
  }
  spec {
    selector = {
      app = "code"
    }
    port {
      port        = local.port
      target_port = local.port
    }
  }
}

module "tjhome_gateway" {
  source    = "github.com/tjpalanca/tjcloud//elements/gateway"
  host      = "home"
  zone_id   = var.main_cloudflare_zone_id
  zone_name = var.main_cloudflare_zone_name
  service = {
    name      = kubernetes_service_v1.metadata.name
    port      = kubernetes_service_v1.spec.port[0].port
    namespace = kubernetes_service_v1.metadata.namespace
  }
  keycloak_realm_id = "tjcloud"
  keycloak_url      = local.keycloak_url
}
