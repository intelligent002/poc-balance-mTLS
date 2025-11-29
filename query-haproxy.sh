#!/usr/bin/env bash
set -euo pipefail

curl -v --location 'https://node-00.intel.r7g.org:8300/' \
  --cacert ./ssl/CA/ca.crt \
  --cert   ./ssl/users/admin/admin.crt \
  --key    ./ssl/users/admin/admin.key \
  --tlsv1.3

loop=2000
for i in $(seq 1 $loop); do
  echo "------------------------------------------------------------ Request $i/$loop ----"
  sleep 2
  curl --silent --show-error --location 'https://node-00.intel.r7g.org:8300/' \
    --cacert ./ssl/CA/ca.crt \
    --cert   ./ssl/users/admin/admin.crt \
    --key    ./ssl/users/admin/admin.key \
    --tlsv1.3 \
    --write-out "\n[Response Code: %{http_code}] [Time: %{time_total}s]\n"
done
