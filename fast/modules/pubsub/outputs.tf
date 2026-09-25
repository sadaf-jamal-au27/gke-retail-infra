output "topic_names" {
  value = [for t in google_pubsub_topic.retail : t.name]
}
