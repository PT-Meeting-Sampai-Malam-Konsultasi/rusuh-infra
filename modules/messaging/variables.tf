variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "queues" {
  description = "Queues to create (each gets a DLQ + redrive policy). Default: the notification queue (Q27)."
  type = map(object({
    visibility_timeout_seconds = optional(number, 300)
    message_retention_seconds  = optional(number, 1209600)
    max_receive_count          = optional(number, 5)
  }))
  default = {
    notification = {}
  }
}
