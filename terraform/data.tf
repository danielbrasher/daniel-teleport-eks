data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

# read and attach a least-privilege policy to pre-existing S3 bucket
data "aws_s3_bucket" "sessions" {
  bucket = var.session_recording_bucket
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # OIDC issuer of the existing EKS cluster
  oidc_issuer       = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_issuer_host  = replace(local.oidc_issuer, "https://", "")
  oidc_provider_arn = "arn:${local.partition}:iam::${local.account_id}:oidc-provider/${local.oidc_issuer_host}"
}
