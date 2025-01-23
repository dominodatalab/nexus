#!/bin/bash

# Registers or validates the data plane with the data plane service, then bootstraps the data plane with
# an initial configuration and security credentials.
# THIS SCRIPT SHOULD BE EXECUTED LOCALLY WITH A KUBE CONTEXT POINTING TO THE DATA PLANE CLUSTER.
#
# Usage:
#         register-data-plane.sh <dps-api-endpoint> <dps-api-key>
# where,
#         dps-api-endpoint -- public API endpoint of the Data Plane Service, include a hostname
#                             and an optional port;
#                             (for development, you may use 'setup-data-plane-service-external.sh'
#                             to configure a tentative API gateway);
#         dps-api-key      -- secret key for accessing Data Plane Service API.

set -o nounset
set -o errexit

JOB_IMAGE=quay.io/domino/data-plane-upgrader:v4.1.19

if [[ $# -ne 2 ]]; then
  echo >&2 "Usage: $0 <dps-api-endpoint> <dps-api-key>"
  exit 1
fi

DPS_ADDRESS=$1
DPS_KEY=$2

NAMESPACE=$(kubectl get deploy -A 2>/dev/null | grep data-plane-agent | cut -d " " -f1)
if [[ -z $NAMESPACE ]]; then
  echo >&2 "Cannot determine the namespace"
  exit 1
fi

cat <<EOF | kubectl create -f -
apiVersion: batch/v1
kind: Job
metadata:
  labels:
    app.kubernetes.io/instance: data-plane
    app.kubernetes.io/name: registration
  generateName: data-plane-registration-
  namespace: $NAMESPACE
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 300
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: data-plane
        app.kubernetes.io/name: registration
    spec:
      containers:
        - command:
            - /bin/sh
            - -c
            - "/home/domino/register-data-plane.sh $DPS_ADDRESS $DPS_KEY"
          image: $JOB_IMAGE
          imagePullPolicy: Always
          name: execute-registration
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
      imagePullSecrets:
        - name: domino-quay-repos
      nodeSelector:
        dominodatalab.com/domino-node: "true"
        dominodatalab.com/node-pool: platform
      restartPolicy: Never
      securityContext:
        fsGroup: 12574
        runAsNonRoot: true
        runAsUser: 12574
        seLinuxOptions:
          type: spc_t
      serviceAccountName: data-plane-upgrader
EOF
