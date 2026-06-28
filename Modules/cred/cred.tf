terraform {
	required_providers {
		local = {
			source = "hashicorp/local"
			version = "~> 2.0"
		}
		vault = {
			source = "hashicorp/vault"
			version = "2.0.0"
		}
	}
}

provider "vault" {
	address = "http://172.18.0.3:8200" 
}