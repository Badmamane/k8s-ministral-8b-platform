# ADR-002: NVIDIA Dynamo as inference layer, Envoy AI Gateway at the edge

- Status: accepted
- Date: 2026-09-06

## Context

Round-robin load balancing is the wrong model for LLM backends: request cost
depends on prompt length, KV-cache reuse and queue depth of each worker. The
platform needs inference-aware routing, replica autoscaling driven by inference
metrics, and an edge that handles API keys, quotas and TLS.

Two inference-aware options exist on Kubernetes:

1. Gateway API Inference Extension (`InferencePool` + endpoint picker) inside a
   Gateway API implementation (kgateway, Envoy AI Gateway, Istio).
2. NVIDIA Dynamo: frontend, KV-cache-aware router, engine workers (vLLM,
   SGLang, TensorRT-LLM), operator with CRDs, scaling adapter and SLA Planner.

## Decision

- Serving engine: vLLM, running Ministral 3 8B Instruct (FP8) on L4 GPUs.
- Inference layer: NVIDIA Dynamo, deployed through the Dynamo Platform Helm
  chart and a `DynamoGraphDeployment`. The Dynamo router performs worker
  selection; the Inference Extension is not used, to avoid two routers.
- Edge: Envoy AI Gateway behind an NLB, responsible only for authentication,
  token quotas, TLS and the `HTTPRoute` to the Dynamo frontend.
- Autoscaling: KEDA targets the `DynamoGraphDeploymentScalingAdapter`
  (Kubernetes Scale subresource) on Dynamo frontend metrics. The SLA Planner is
  a later phase, together with disaggregated prefill/decode.
- LoRA adapters trained by Slurm jobs are loaded through `DynamoModel`, so
  training and serving share the platform end to end.

## Consequences

- On a single GPU the router has one choice; its value is demonstrated in the
  e2e benchmark with two replicas.
- Dynamo pins runtime compatibility to the worker image tag; images are pinned
  to semantic versions, never `latest`.
- Frontend, router, operator and Planner are CPU pods; no additional GPU cost.

## Alternatives rejected

- ALB + plain vLLM Deployment: no inference-aware routing.
- Gateway API Inference Extension as primary router: valid and vendor-neutral
  (kgateway is used by llm-d); rejected here to keep one routing layer and to
  exercise the Dynamo operator model.
- TensorRT-LLM / Triton as primary engine: better raw throughput, slower
  iteration due to per-GPU engine builds; kept as a benchmark track.
