#!/bin/bash

# Bootstraps the data plane with initial configuration and security credentials.
# Before running this script, acquire a Kubernetes context of the DATA PLANE.
#
# Usage:
#         bootstrap-data-plane.sh [--force] <bootstrap-payload>
#
# where,
#         --force           -- force the agent to re-bootstrap.
#         bootstrap-payload -- the value of 'agent.vault.bootstrap_payload' from
#                              a freshly generated helm install command.

set -o nounset
set -o errexit

FORCE=false

while [[ "$#" -gt 1 ]]; do
    case $1 in
        --force)
          FORCE=true
        ;;
        *)
          echo >&2 "Unknown argument: $1"
          exit 1
        ;;
    esac
    shift
done

PAYLOAD=$1
if [[ -z "$PAYLOAD" ]]; then
  echo "Usage: $0 [--kubeconfig <file>] <bootstrap-payload>"
  exit 1
fi

NAMESPACE=$(kubectl get deploy -A 2>/dev/null | grep data-plane-agent | cut -f 1 -d " ")
if [[ -z $NAMESPACE ]]; then
  echo >&2 "Cannot determine the namespace"
  exit 1
fi

cat <<EOF | kubectl apply -f >/dev/null -
apiVersion: v1
data:
  payload: $PAYLOAD
kind: Secret
metadata:
  name: agent-bootstrap
  namespace: $NAMESPACE
type: Opaque
EOF

if [[ $FORCE == true ]]; then
  kubectl delete secret -n $NAMESPACE --ignore-not-found=true agent-app-role >/dev/null 2>&1 # Intentionally suppressing stderr
  kubectl delete pod -n $NAMESPACE \
    -l app.kubernetes.io/instance=data-plane,app.kubernetes.io/name=agent >/dev/null
fi
