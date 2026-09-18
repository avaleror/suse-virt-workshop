#!/bin/bash
# Exercise 1 (The Arrival) self-check.
#
# Adapted from suse-virt-rodeo's own Instruqt check for this chapter
# (01-the-arrival-welcome/check-kvm-host) — same two checks, same logic,
# just pointed at this workshop's kubeconfig path instead of Instruqt's.
#
# Run from the KVM/EC2 host, as the user (or via sudo) that ran `rodeo up`:
#   ./checks/check-exercise-1.sh

set -uo pipefail
export KUBECONFIG="${KUBECONFIG:-$HOME/.rodeo/harvester-kubeconfig}"

# All 3 Harvester nodes must be Ready
READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready' || echo 0)
if [[ "$READY" -lt 3 ]]; then
  echo "FAIL: Only ${READY}/3 Harvester nodes are Ready. Wait for the cluster to finish initialising."
  exit 1
fi

# Longhorn storage nodes must all be schedulable
SCHEDULABLE=$(kubectl get nodes.longhorn.io -n longhorn-system --no-headers 2>/dev/null | \
  grep -c 'True' || echo 0)
TOTAL=$(kubectl get nodes.longhorn.io -n longhorn-system --no-headers 2>/dev/null | \
  wc -l | tr -d ' ')
if [[ "$SCHEDULABLE" -lt "$TOTAL" || "$TOTAL" -eq 0 ]]; then
  echo "FAIL: Not all Longhorn storage nodes are schedulable (${SCHEDULABLE}/${TOTAL}). Check the Longhorn dashboard."
  exit 1
fi

echo "PASS: All 3 nodes Ready and Longhorn storage is healthy"
