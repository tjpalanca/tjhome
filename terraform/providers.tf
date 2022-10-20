provider "keycloak" {
  client_id = "admin-cli"
  username  = var.keycloak_admin_username
  password  = var.keycloak_admin_password
  url       = local.keycloak_url
  base_path = ""
}

data "terraform_remote_state" "tjcloud" {
  backend = "remote"
  config = {
    organization = "tjpalanca"
    workspaces = {
      name = "tjcloud"
    }
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.tjcloud.outputs.kubeconfig.endpoint
  token                  = data.terraform_remote_state.tjcloud.outputs.kubeconfig.token
  cluster_ca_certificate = data.terraform_remote_state.tjcloud.outputs.kubeconfig.cluster_ca_certificate
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
