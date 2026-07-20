# WORKING WORKAROUND (terramate 0.17.1).
#
# The caller passes a `node_pools` map, but a bundle can't turn that into N
# stacks. So we pre-author a fixed number of `condition`-gated slots. Here we
# hard-cap at 3 pools ("a", "b", "c"); a 4th pool in the input is silently
# dropped. Each block below is nearly identical — exactly the boilerplate a
# `for_each` would erase.

define "bundle" "metadata" {
  class       = "cluster"
  version     = "0.1.0"
  name        = "cluster"
  description = "Demo EKS-style cluster bundle: one stack per node pool"
}

define "bundle" {
  input "cluster_name" {
    type   = string
    prompt = "Cluster name"
  }

  # The data we would love to iterate over. Keys are pool names.
  input "node_pools" {
    type    = map(any)
    prompt  = "Node pools, keyed by name"
    default = {}
  }

  scaffolding {
    path = "stacks/clusters/${bundle.input.cluster_name.value}"
    name = bundle.input.cluster_name.value
  }

  # ---- one hand-written block per possible pool (the workaround) ----

  define bundle stack "node-pool-a" {
    condition = tm_contains(tm_keys(bundle.input.node_pools.value), "a")
    metadata {
      name = "node-pool-a"
      tags = ["node-pool", "a"]
    }
  }

  define bundle stack "node-pool-b" {
    condition = tm_contains(tm_keys(bundle.input.node_pools.value), "b")
    metadata {
      name = "node-pool-b"
      tags = ["node-pool", "b"]
    }
  }

  define bundle stack "node-pool-c" {
    condition = tm_contains(tm_keys(bundle.input.node_pools.value), "c")
    metadata {
      name = "node-pool-c"
      tags = ["node-pool", "c"]
    }
  }
}
