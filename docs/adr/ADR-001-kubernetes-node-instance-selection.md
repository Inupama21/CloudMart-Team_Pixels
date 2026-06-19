# ADR-001: Kubernetes Node Instance Selection

## Status

Accepted

## Context

CloudMart needs at least two worker nodes, enough memory for five replicated services, and a
low assignment operating cost. The team compared:

- `t3.medium`: general-purpose x86, 2 vCPU and 4 GiB RAM.
- `c7g.medium`: ARM compute-optimised, 1 vCPU and 2 GiB RAM.
- `m7g.medium`: ARM general-purpose, 1 vCPU and 4 GiB RAM.

Exact regional prices change over time, so the final report must attach a dated AWS Pricing
Calculator export. ARM alternatives may reduce compute price but require building and scanning
multi-architecture container images. Compute-optimised nodes also provide less memory for the
mixed CloudMart workload.

## Decision

Use `t3.medium` for the initial production and staging baseline, with at least two production
nodes spread across availability zones. Use Spot capacity only for non-critical staging
workloads. Review AWS Compute Optimizer after sufficient telemetry exists.

## Consequences

- Existing x86 images and dependencies run without architecture changes.
- The 4 GiB memory allocation is safer for multiple small services than a 2 GiB node.
- Burstable CPU suits an educational workload with intermittent demonstrations.
- Sustained CPU workloads may consume credits and become less cost-effective.
- ARM savings are deferred until the CI pipeline publishes verified multi-architecture images.

## Alternatives Considered

- `c7g.medium`: rejected because lower memory and ARM migration risk outweigh the expected
  saving for the current mixed workload.
- `m7g.medium`: attractive for future use, but rejected initially because all images and native
  dependencies have not been proven on ARM.
- Larger general-purpose instances: rejected for the baseline because current resource requests
  do not justify the additional monthly cost.

