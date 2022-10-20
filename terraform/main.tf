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

module "keycloak_realm" {
  source      = "github.com/tjpalanca/tjcloud//elements/keycloak_realm"
  name        = "tjhome"
  name_html   = "<div class='logo-text'><img style='max-height: 120px;' src='https://tjpalanca.com/assets/logo/logo-small.png'></div>"
  login_theme = "social"
  google = {
    client_id     = var.google_client_id
    client_secret = var.google_client_secret
  }
}

resource "kubernetes_service_v1" "service" {
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

module "gateway" {
  source    = "github.com/tjpalanca/tjcloud//elements/gateway"
  host      = "home"
  zone_id   = var.main_cloudflare_zone_id
  zone_name = var.main_cloudflare_zone_name
  service = {
    name      = kubernetes_service_v1.service.metadata[0].name
    port      = kubernetes_service_v1.service.spec[0].port[0].port
    namespace = kubernetes_service_v1.service.metadata[0].namespace
  }
  keycloak_realm_id = module.keycloak_realm.realm.id
  additional_redirect_uris = [
    "https://oauth-redirect.googleusercontent.com/r/*",
    "https://oauth-redirect-sandbox.googleusercontent.com/r/YOUR_PROJECT_ID/*"
  ]
  keycloak_url = local.keycloak_url
}
