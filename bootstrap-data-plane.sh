#!/bin/sh

# Bootstraps the data plane with initial configuration and security credentials.
# Before running this script, acquire a Kubernetes context of the DATA PLANE.
#
# Usage:
#         bootstrap-data-plane.sh <bootstrap-payload>
# where,
#         bootstrap-payload -- the value of 'agent.vault.bootstrap_payload' from
#                              a freshly generated helm install command.

# This implementation will change as more Data Plane Service functionality becomes available.

PAYLOAD=$1
if [[ -z $PAYLOAD ]]; then
  echo "Usage: $0 <bootstrap-payload>"
  exit 1
fi

NAMESPACE=$(kubectl get deploy -A | grep data-plane-agent | cut -f 1 -d " ")
if [[ -z $NAMESPACE ]]; then
  echo >&2 "Cannot determine the namespace"
  exit 1
fi

cat <<EOF | kubectl apply -f -
apiVersion: v1
data:
  payload: $PAYLOAD
kind: Secret
metadata:
  name: agent-bootstrap
  namespace: $NAMESPACE
type: Opaque
EOF
