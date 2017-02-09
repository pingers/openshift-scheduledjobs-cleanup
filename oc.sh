#!/bin/sh

export KUBECONFIG=/tmp/.kube

set -e

DEFAULT_NAMESPACE=$(eval cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

oc login https://$KUBERNETES_PORT_443_TCP_ADDR:$KUBERNETES_SERVICE_PORT_HTTPS \
  --token `cat /var/run/secrets/kubernetes.io/serviceaccount/token` \
  --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
oc get jobs -n ${DEFAULT_NAMESPACE} > /tmp/jobs
tail -n +2 /tmp/jobs > /tmp/jobs-without-header

while read JOB_WITH_STATS
do
    JOB=$(eval echo "${JOB_WITH_STATS}" | awk '{print $1}')
    SUCCESSFUL_RUN=$(eval echo "${JOB_WITH_STATS}" | awk '{print $3}')
    if [ ${SUCCESSFUL_RUN} == "0" ]; then
      echo "Successfully ended job ${JOB}, delete it"
      oc delete job ${JOB} -n ${DEFAULT_NAMESPACE}
    else
      echo "${JOB} not successfully ended"
    fi
done < /tmp/jobs-without-header