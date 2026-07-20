# Terramate demo: data-driven `define bundle stack` iteration

Minimal, self-contained reproduction backing the Terramate feature request
**"Allow `define bundle stack` blocks to iterate over an input map/list (data-driven stack expansion)"**.

Verified against `terramate 0.17.1` (standard distribution).

## The gap in one sentence

A `define bundle stack` block accepts **only** a `condition` (bool) attribute — there is no `for_each`/`iterator`, and `tm_dynamic` is not a recognized block inside `define "bundle"`. So a bundle **cannot expand a map/list input into N stacks**; the stack count is static and must be hand-authored, one labeled block per stack.

This matters for any bundle whose fan-out is data-driven — e.g. an EKS cluster bundle where the caller passes a `node_pools` (or `clusters`) map and expects one stack per entry.

## Layout

| Path | What it is |
|------|------------|
| `bundles/cluster/bundle.tm.hcl` | The **working workaround** — N pre-authored, `condition`-gated stack blocks. Parses and scaffolds. |
| `bundles/cluster/desired-for_each.hcl.txt` | What we **wish** worked: `for_each` on a `define bundle stack`. Rejected by the schema. |
| `bundles/cluster/desired-tm_dynamic.hcl.txt` | The other natural form: `tm_dynamic "stack"`. Rejected as an unknown block. |

The two `desired-*.hcl.txt` files carry a `.txt` suffix on purpose so they are **not** parsed by `terramate` (mixing them into the tree would fail the whole project). Rename either to `*.tm.hcl` and run `terramate generate` to reproduce the error quoted in its header.

## Reproduce

```console
$ terramate --version
0.17.1

# Works: the static, condition-gated workaround
$ terramate scaffold cluster   # (or `terramate ui`), then `terramate generate`

# Fails: rename the desired snippet in and generate
$ mv bundles/cluster/desired-for_each.hcl.txt bundles/cluster/desired.tm.hcl
$ terramate generate
terramate schema error: unrecognized "define.bundle.stack" attribute "for_each" — valid attributes are [condition]

$ mv bundles/cluster/desired-tm_dynamic.hcl.txt bundles/cluster/desired.tm.hcl
$ terramate generate
terramate schema error: unexpected block type "tm_dynamic"
```

## Why the workaround doesn't scale

To support up to *N* node pools you must pre-author *N* `condition`-gated `define bundle stack` blocks and cap *N* arbitrarily. The caller's data can't grow the stack set past what the bundle author hand-wrote, and every unused slot is dead config. The whole point of a bundle is to be the templating layer — but the one dimension it can't template is *how many stacks*.
