resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name        = "${var.project}-${var.environment}-${each.key}"
  description = each.value.description

  tags = {
    Name = "${var.project}-${var.environment}-${each.key}"
  }
}
