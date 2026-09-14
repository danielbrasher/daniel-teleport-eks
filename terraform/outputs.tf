output "auth_role_arn" {
  description = "Annotate the teleport SA with this (eks.amazonaws.com/role-arn)."
  value       = aws_iam_role.auth.arn
}

output "discovery_role_arn" {
  description = "Already referenced in the kube-agent values; confirm it matches."
  value       = aws_iam_role.discovery.arn
}

output "external_secrets_role_arn" {
  description = "Goes into infrastructure/external-secrets/ (SA annotation + ClusterSecretStore)."
  value       = aws_iam_role.external_secrets.arn
}

output "cert_manager_role_arn" {
  description = "Set as CERT_MANAGER_ROLE_ARN in infrastructure/base/cluster-vars.yaml."
  value       = aws_iam_role.cert_manager.arn
}

output "ebs_csi_role_arn" {
  description = "IRSA role on the aws-ebs-csi-driver addon, backs the gp3 StorageClass."
  value       = try(aws_iam_role.ebs_csi[0].arn, null)
}

output "route53_hosted_zone_id" {
  description = "Zone cert-manager solves DNS-01 in - pin it as hostedZoneID on the ClusterIssuer solver to skip the zone lookup."
  value       = data.aws_route53_zone.this.zone_id
}

output "ec2_node_role_arn" {
  description = "Attach to discoverable EC2 instances - allow-list it on the IAM join token."
  value       = try(aws_iam_role.ec2_node[0].arn, null)
}

output "ec2_node_instance_profile" {
  value = try(aws_iam_instance_profile.ec2_node[0].name, null)
}

output "ci_role_arn" {
  description = "Set as the AWS_ROLE_ARN repo variable for GitHub Actions."
  value       = try(aws_iam_role.ci[0].arn, null)
}

output "license_secret_arn" {
  value = aws_secretsmanager_secret.license.arn
}

output "flux_github_app_secret_arn" {
  description = "Read by ESO for the github-status Provider's GitHub App credentials."
  value       = aws_secretsmanager_secret.flux_github_app.arn
}

output "flux_github_dispatch_app_secret_arn" {
  description = "Read by ESO for the github-dispatch Provider's GitHub App credentials."
  value       = aws_secretsmanager_secret.flux_github_dispatch_app.arn
}

output "iam_join_allow_arns" {
  description = "Paste these into the TeleportProvisionToken allow rules."
  value = {
    discovery_pod = "arn:${local.partition}:sts::${local.account_id}:assumed-role/${aws_iam_role.discovery.name}/*"
    ec2_nodes     = try("arn:${local.partition}:sts::${local.account_id}:assumed-role/${aws_iam_role.ec2_node[0].name}/*", null)
  }
}
