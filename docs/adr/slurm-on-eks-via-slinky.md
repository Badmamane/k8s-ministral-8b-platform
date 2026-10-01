# ADR-001: Run Slurm on EKS with Slinky instead of a dedicated EC2 cluster

- Status: accepted
- Date: 2026-09-07

## Context

The platform must run two GPU workloads with opposite profiles on AWS:

- batch fine-tuning jobs (LoRA on a small language model) that want a scheduler
  with queues, fair-share, accounting and multi-node launches;
- online inference (OpenAI-compatible API) that wants request-level routing and
  replica autoscaling.

Both should share one accelerator pool that scales to zero when idle, be fully
described as code, and be reproducible from CI with a single command.

Three AWS-native ways to run Slurm were evaluated.

| Option | Nature | Fit |
|---|---|---|
| AWS ParallelCluster | Slurm on EC2, AWS-managed tooling, shared FS | Best for pure HPC; separate cluster from inference; no Kubernetes primitives |
| SageMaker HyperPod | Managed, self-healing Slurm or EKS clusters | Enterprise scale and price; limited GitOps/Terraform control |
| Slinky on EKS | Slurm operator running the Slurm daemons as Kubernetes workloads | One pool for batch + inference; Kubernetes RBAC, GitOps, Karpenter apply to both |

## Decision

Deploy Slurm with the SchedMD Slinky `slurm-operator` on Amazon EKS. Slurm
control daemons (slurmctld, slurmdbd, login, slurmrestd) run on an always-on
CPU node group; `slurmd` NodeSets run on a Karpenter-managed GPU NodePool that
also hosts the inference workers. KEDA scales NodeSets to zero on
`slurm_jobs_pending`; Karpenter provisions and removes the underlying g6
Spot instances.

## Consequences

Positive:

- A single GPU pool, one autoscaling mechanism and one security model (Pod
  Identity, RBAC, NetworkPolicy) cover both training and serving.
- Everything above the AWS layer is Kubernetes objects synced by Argo CD, so the
  environment is reproducible and destroyable from CI.
- The design matches the reference published by AWS (AI on EKS "Slinky Slurm"
  blueprint) and the deployment model NVIDIA documents for Slinky.

Negative / accepted:

- More moving parts than ParallelCluster for a single-tenant HPC use case; the
  EKS control plane and the operator are paid for by the shared-pool benefit.
- Slinky is younger than ParallelCluster; custom `slurmd` images are needed
  when the CUDA base image and Slurm's GLIBC requirements diverge.
- EFA/NCCL high-performance networking is not configured; the platform targets
  single-GPU and small multi-node jobs on g6 instances.

## Alternatives rejected

- ParallelCluster: rejected because inference would need a second, separately
  scaled and secured environment.
- HyperPod: rejected for cost and because the Terraform/GitOps surface is
  limited; noted as the managed path in a production context.
