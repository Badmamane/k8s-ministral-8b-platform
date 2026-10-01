#!/usr/bin/env bash
# ------ Fail if resources tagged Project=<project> still exist outside the bootstrap stack.
# ------ The Resource Groups Tagging index lags deletions by minutes to hours, so every
# ------ candidate is confirmed with the service's own describe call before it counts.
set -euo pipefail

PROJECT=${PROJECT:-k8s-ministral-8b}
REGION=${AWS_REGION:-us-east-1}
ENV_NAME=${ENV:-dev}

# ------ Allowed to survive: the bootstrap stack and index entries of resources that never
# ------ persist (pod identity associations, SG rules, instant fleets) or that nobody can
# ------ delete (EFS automatic-backup recovery points, expiring on their own).
ALLOW="tfstate|gha-plan|gha-lifecycle|cloudtrail|oidc-provider/|:budget/|secret:${PROJECT}-${ENV_NAME}/|podidentityassociation|security-group-rule/|:fleet/|:recovery-point:"

ec2() { aws ec2 "$@" --region "$REGION" >/dev/null 2>&1; }

# ------ exists ARN: 0 when the resource is still there, 1 when it is gone or bootstrap-owned
exists() {
  local arn=$1 id=${1##*/} state alias
  case "$arn" in
    arn:aws:kms:*:key/*)
      state=$(aws kms describe-key --region "$REGION" --key-id "$arn" --query KeyMetadata.KeyState --output text 2>/dev/null || echo gone)
      alias=$(aws kms list-aliases --region "$REGION" --key-id "$arn" --query 'Aliases[0].AliasName' --output text 2>/dev/null || true)
      case "$state|$alias" in gone*|PendingDeletion*|*-tfstate|*-secrets|*-cloudtrail) return 1 ;; esac ;;
    arn:aws:ec2:*:natgateway/*)
      state=$(aws ec2 describe-nat-gateways --region "$REGION" --nat-gateway-ids "$id" --query 'NatGateways[0].State' --output text 2>/dev/null || echo deleted)
      [ "$state" != "deleted" ] || return 1 ;;
    arn:aws:ec2:*:instance/*)
      state=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$id" --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo terminated)
      case "$state" in terminated|None|"") return 1 ;; esac ;;
    arn:aws:ec2:*:volume/*)            ec2 describe-volumes --volume-ids "$id" || return 1 ;;
    arn:aws:ec2:*:security-group/*)    ec2 describe-security-groups --group-ids "$id" || return 1 ;;
    arn:aws:ec2:*:vpc-endpoint/*)      ec2 describe-vpc-endpoints --vpc-endpoint-ids "$id" || return 1 ;;
    arn:aws:ec2:*:subnet/*)            ec2 describe-subnets --subnet-ids "$id" || return 1 ;;
    arn:aws:ec2:*:vpc/*)               ec2 describe-vpcs --vpc-ids "$id" || return 1 ;;
    arn:aws:ec2:*:internet-gateway/*)  ec2 describe-internet-gateways --internet-gateway-ids "$id" || return 1 ;;
    arn:aws:ec2:*:route-table/*)       ec2 describe-route-tables --route-table-ids "$id" || return 1 ;;
    arn:aws:ec2:*:network-interface/*) ec2 describe-network-interfaces --network-interface-ids "$id" || return 1 ;;
    arn:aws:ec2:*:elastic-ip/*)        ec2 describe-addresses --allocation-ids "$id" || return 1 ;;
    arn:aws:ec2:*:launch-template/*)   ec2 describe-launch-templates --launch-template-ids "$id" || return 1 ;;
    arn:aws:ec2:*:network-acl/*)       ec2 describe-network-acls --network-acl-ids "$id" || return 1 ;;
    arn:aws:ec2:*:vpc-flow-log/*)      [ "$(aws ec2 describe-flow-logs --region "$REGION" --filter "Name=flow-log-id,Values=$id" --query 'length(FlowLogs)' --output text 2>/dev/null)" != "0" ] || return 1 ;;
  esac
  return 0   # unknown kinds count as live: better a false alarm than a missed bill
}

candidates=$(aws resourcegroupstaggingapi get-resources --region "$REGION" \
  --tag-filters "Key=Project,Values=$PROJECT" \
  --query 'ResourceTagMappingList[].ResourceARN' --output text | tr '\t' '\n' | grep -Ev "$ALLOW" || true)

live=""
for arn in $candidates; do exists "$arn" && live="$live$arn"$'\n'; done
if [ -n "$live" ]; then echo "orphaned resources:"; printf '%s' "$live"; exit 1; fi
echo "orphan-check: clean"
