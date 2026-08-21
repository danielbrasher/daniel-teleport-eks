###############################################################################
# EC2 auto-discovery plumbing
#
# The Discovery Service finds tagged instances, then asks SSM to run this
# document on them. The document downloads the installer script that your own
# Proxy Service serves and runs it with the IAM join token.
#
# Verify the document body against the version Teleport publishes for your
# release before you rely on it:
#   https://goteleport.com/docs/enroll-resources/auto-discovery/servers/ec2-discovery/
###############################################################################

resource "aws_ssm_document" "installer" {
  name            = var.ssm_document_name
  document_type   = "Command"
  document_format = "YAML"

  content = <<-DOC
    schemaVersion: '2.2'
    description: Install Teleport and join it to ${var.teleport_cluster_name}
    parameters:
      token:
        type: String
        description: Teleport provision token name
      scriptName:
        type: String
        description: Installer script served by the Proxy Service
        default: ${var.installer_script_name}
      sshdConfigPath:
        type: String
        description: Path to sshd_config
        default: /etc/ssh/sshd_config
    mainSteps:
      - action: aws:downloadContent
        name: downloadContent
        inputs:
          sourceType: HTTP
          destinationPath: /tmp/installTeleport.sh
          sourceInfo: '{"url": "https://${var.teleport_cluster_name}/webapi/scripts/installer/{{ scriptName }}"}'
      - action: aws:runShellScript
        name: runShellScript
        inputs:
          timeoutSeconds: '300'
          runCommand:
            - /bin/sh /tmp/installTeleport.sh "{{ token }}"
  DOC
}

# ---- Instance role for discoverable EC2 nodes -------------------------------
# Two jobs: let SSM manage the instance, and give it an AWS identity the
# Teleport IAM join token can allow (see teleport-resources/tokens/).
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_node" {
  count              = var.create_node_instance_profile ? 1 : 0
  name               = "${var.name_prefix}-ec2-node"
  description        = "Discoverable EC2 instances: SSM managed + Teleport IAM join"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ec2_node_ssm" {
  count      = var.create_node_instance_profile ? 1 : 0
  role       = aws_iam_role.ec2_node[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_node" {
  count = var.create_node_instance_profile ? 1 : 0
  name  = "${var.name_prefix}-ec2-node"
  role  = aws_iam_role.ec2_node[0].name
}
