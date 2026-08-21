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

output "ec2_node_role_arn" {
  description = "Attach to discoverable EC2 instances; allow-list it on the IAM join token."
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

output "iam_join_allow_arns" {
  description = "Paste these into the TeleportProvisionTokenV2 allow rules."
  value = {
    discovery_pod = "arn:${local.partition}:sts::${local.account_id}:assumed-role/${aws_iam_role.discovery.name}/*"
    ec2_nodes     = try("arn:${local.partition}:sts::${local.account_id}:assumed-role/${aws_iam_role.ec2_node[0].name}/*", null)
  }
}
