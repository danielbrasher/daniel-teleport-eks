variable "region" {
  type        = string
  default     = "us-west-1"
  description = "Region containing EKS cluster, S3 bucket and discoverable EC2 instances"
}

variable "name_prefix" {
  type        = string
  default     = "daniel-teleport"
  description = "Prefix for all created IAM roles, policies, and secrets"
}

variable "eks_cluster_name" {
  type        = string
  default     = "daniel-eks-cluster"
  description = "Preexisting EKS cluster"
}

variable "teleport_namespace" {
  type        = string
  default     = "teleport"
  description = "Namespace for teleport-cluster release"
}

variable "teleport_cluster_name" {
  type        = string
  default     = "teleport-eks.dbteleport.com"
  description = "Teleport cluster / public proxy address (to build SSM installer URL)"
}

variable "session_recording_bucket" {
  type        = string
  default     = "daniel-teleport-sessions-eks"
  description = "Pre-existing S3 bucket for session recordings"
}

variable "ssm_document_name" {
  type        = string
  default     = "Daniel-TeleportDiscoveryInstaller"
  description = "Must match discovery_service.aws[].ssm.document_name in the kube-agent values"
}

variable "installer_script_name" {
  type        = string
  default     = "default-installer"
  description = "Teleport installer script served at /webapi/scripts/installer/<name>"
}

variable "discoverable_tag" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "daniel-teleport-discoverable"
    value = "true"
  }
  description = "Tag the Discovery Service matches on. Also scopes ssm:SendCommand."
}

variable "external_secrets_namespace" {
  type    = string
  default = "external-secrets"
}

variable "external_secrets_service_account" {
  type    = string
  default = "external-secrets"
}

variable "cert_manager_namespace" {
  type    = string
  default = "cert-manager"
}

variable "cert_manager_service_account" {
  type    = string
  default = "cert-manager"
}

variable "dns_zone_name" {
  type        = string
  default     = "dbteleport.com"
  description = "Public Route53 zone cert-manager solves DNS-01 challenges in"
}

variable "manage_ebs_csi_addon" {
  type        = bool
  default     = true
  description = "Attach the aws-ebs-csi-driver addon (+ its IRSA role) to the pre-existing cluster. Required for the gp3 StorageClass the Postgres StatefulSet claims from."
}

variable "create_node_instance_profile" {
  type        = bool
  default     = true
  description = "Create the instance role/profile that discoverable EC2 instances use (SSM + IAM join)"
}

variable "github_repo" {
  type        = string
  default     = "danielbrasher/daniel-teleport-eks"
  description = "Owner/repo allowed to assume the CI role via GitHub OIDC"
}

variable "create_github_oidc_provider" {
  type        = bool
  default     = false
  description = "Set true only if token.actions.githubusercontent.com is not already an OIDC provider in this account" # it's already a provider on our shared account
}

variable "manage_ci_role" {
  type        = bool
  default     = true
  description = "Create the IAM role GitHub Actions assumes for terraform plan/apply"
}

variable "tags" {
  type = map(string)
  default = {
    app          = "teleport"
    "managed-by" = "terraform"
    owner        = "danielbrasher"
  }
}
