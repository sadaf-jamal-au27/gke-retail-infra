variable "project_id" { type = string }
variable "region" { type = string }
variable "env" { type = string }

variable "events" {
  type = list(string)
  default = [
    "order-placed",
    "cart-updated",
    "payment-captured",
    "inventory-adjusted",
    "user-authenticated",
    "notification-sent",
    "audit-entry-recorded",
  ]
}
