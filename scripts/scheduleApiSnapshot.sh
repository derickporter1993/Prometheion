#!/usr/bin/env bash
# Schedules hourly API usage snapshots
# Usage: ./scripts/scheduleApiSnapshot.sh CCX
alias_name="${1:-CCX}"
# Schedule (top of hour, hourly)
sf apex run -u "$alias_name" -f /dev/stdin <<'APEX'
System.schedule('CCX_API_Snapshot', '0 0 * * * ?', new ApiUsageSnapshot());
APEX
