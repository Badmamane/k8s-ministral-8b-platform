# ADR-003: Destroy by ownership and finalizers, not by cleanup scripts

- Status: accepted
- Date: 2026-09-07

## Context

Controllers running inside the cluster create AWS resources Terraform never
sees: the AWS Load Balancer Controller creates NLB/ALB, target groups and
security groups; the EBS and EFS CSI drivers create volumes and access points;
Karpenter creates EC2 instances and ENIs. A plain `terraform destroy` removes
the cluster while those resources still exist, and the VPC destroy then hangs.

The usual fix is a pre-destroy script that deletes Services, Ingresses, PVCs
and NodePools with `kubectl`, then polls AWS. It works, but it encodes the
platform's structure a second time, in bash, and drifts.

## Decision

Terraform owns the root objects of each cascade, and Kubernetes finalizers do
the waiting:

- The Argo CD root `Application` is created by the `gitops` module with the
  `resources-finalizer.argocd.argoproj.io` finalizer. Destroying the unit
  deletes it; Argo cascades to every managed object; the Load Balancer
  Controller removes load balancers before the deletes complete.
- Karpenter `NodePool` and `EC2NodeClass` are created by the `karpenter`
  module, not by Argo CD. Destroying the unit deletes them; Karpenter's
  finalizer drains and terminates every instance first.
- Volumes are reclaimed by policy: `StorageClass reclaimPolicy: Delete` and
  `persistentVolumeClaimRetentionPolicy.whenDeleted: Delete` on StatefulSets.

Deletion order between children matters when one child owns cloud resources
through a controller that is itself a child: the Load Balancer Controller must
outlive every Service of type LoadBalancer. Two root Applications express that:
`root` owns the platform and observability groups, `workloads` owns everything
that runs on the platform (Slurm, inference, the gateway). Terraform creates
`workloads` after `root`, so it destroys it first, and Helm's uninstall waits
for the Application to disappear, which its finalizer only allows once the
cascade, load balancers included, is complete.

The same rule applies one level down: a controller must outlive the objects it
reconciles, or their finalizers and conversion webhooks hang. Operators and their
CRDs (Slinky, Dynamo, Envoy Gateway, Agent Router) live under `root`; the custom
resources they manage (the Slurm cluster, the DynamoGraphDeployment, the Gateway)
live under `workloads`.

One guard remains, as a Terragrunt `after_hook` on the `karpenter` unit: a
poll on EC2 until no instance tagged `karpenter.sh/nodepool` for the cluster
exists. A tag-based orphan check runs after every destroy in CI and fails the
run if anything tagged with the project survived.


## Consequences

- No imperative cleanup step; the destroy order is the reverse of the
  dependency graph and the cleanup is expressed as ownership and policy.
- A failing orphan check is a modelling gap to fix declaratively, not a reason
  to extend a script.
- Helm releases with `wait = true` are used for the root objects; Helm's
  uninstall waits for the released objects to be gone, so finalizers gate the
  Terraform graph without a reachable cluster at plan time.
