resource "google_pubsub_topic" "retail" {
  for_each = toset(var.events)
  name     = "retail-${var.env}.${each.key}"
}
