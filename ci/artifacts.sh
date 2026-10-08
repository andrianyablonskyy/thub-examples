#!/bin/sh
# ci/artifacts.sh name link [file] — append one entry to $THUB_ARTIFACTS_FILE (§7.3)
name=$1 link=$2 file=${3:-}
size=null; [ -n "$file" ] && size=$(wc -c < "$file" | tr -d ' ')
entry=$(printf '{"name":"%s","size":%s,"link":"%s","timestamp":%s}' "$name" "$size" "$link" "$(date +%s)")
if [ -s "$THUB_ARTIFACTS_FILE" ]; then   # plain shell, not sed: signed URLs contain & and |
  list=$(cat "$THUB_ARTIFACTS_FILE")
  printf '%s,%s]\n' "${list%]}" "$entry" > "$THUB_ARTIFACTS_FILE"
else
  printf '[%s]\n' "$entry" > "$THUB_ARTIFACTS_FILE"
fi
