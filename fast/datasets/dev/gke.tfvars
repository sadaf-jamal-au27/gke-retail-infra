master_ipv4_cidr       = "172.16.0.0/28"
master_authorized_cidr = "0.0.0.0/0"

# First apply creates gke-node-dev + IAM only (cluster stays on default SA).
# After `tf.sh dev gke plan` shows no cluster replace, set this true.
use_custom_node_sa = false
