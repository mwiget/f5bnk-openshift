#!/bin/bash
oc apply -f 00-role-dpu.yaml
oc apply -f mcp-dpu.yaml
echo "waiting for dpu machineconfig status True ..."
sleep 1
oc wait mcp/dpu \
  --for=jsonpath='{.status.conditions[?(@.type=="Updated")].status}'=True \
  --timeout=10m

oc get mcp dpu -o wide
echo ""
oc extract -n openshift-machine-api secret/dpu-user-data-managed --keys=userData --to=- > dpu.ign
echo ""
ls -l dpu.ign
