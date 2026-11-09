variable "project" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "secrets" {
  description = "Secret shells to create: map of name -> { description }. Values are NEVER set here (see README)."
  type = map(object({
    description = optional(string, "")
  }))
  default = {}
}
