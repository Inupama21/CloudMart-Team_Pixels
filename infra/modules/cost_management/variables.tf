variable "project" {
  description = "Project tag value used by CloudMart resources"
  type        = string
}

variable "environment" {
  description = "Environment covered by this budget"
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly AWS cost budget in USD"
  type        = number
}

variable "notification_emails" {
  description = "Email addresses that receive budget notifications"
  type        = list(string)

  validation {
    condition     = length(var.notification_emails) > 0
    error_message = "At least one budget notification email is required."
  }
}

