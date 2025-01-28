#!/bin/bash

# Bootstraps the data plane with initial configuration and security credentials.
# Before running this script, acquire a Kubernetes context of the DATA PLANE.
#
# Usage:
#         bootstrap-data-plane.sh [--kubeconfig <file>] <bootstrap-payload>
# where,
#         bootstrap-payload -- the value of 'agent.vault.bootstrap_payload' from
#                              a freshly generated helm install command.

# This implementation will change as more Data Plane Service functionality becomes available.

KUBECTL_OPTS=""

while [[ "$#" -gt 1 ]]; do
    case $1 in
        --kubeconfig)
          KUBECTL_OPTS="$KUBECTL_OPTS --kubeconfig $2"
          shift
        ;;
        # Add more options here as needed
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

echo "*** PAYLOAD=>$PAYLOAD<"

NAMESPACE=$(kubectl get deploy -A | grep data-plane-agent | cut -f 1 -d " ")
if [[ -z $NAMESPACE ]]; then
  echo >&2 "Cannot determine the namespace"
  exit 1
fi

cat <<EOF | kubectl $KUBECTL_OPTS apply -f -
apiVersion: v1
data:
  payload: $PAYLOAD
kind: Secret
metadata:
  name: agent-bootstrap
  namespace: $NAMESPACE
type: Opaque
EOF
