#!/bin/sh
# ci/publish-junit.sh <storage-url> — upload every JUnit XML file under results/ or artifacts/
# (in the work directory, or a folder of it such as src/) to <storage-url>/<job id>/, and
# list each one in $THUB_ARTIFACTS_FILE, so the PR comment and the Job Summary show every
# test case (README §7.6). Credentials: ART_TOKEN (--env). Run it after the tests, then
# exit with their code: it never changes the verdict.
base="${1%/}/$THUB_JOB_ID"
here=$(cd "$(dirname "$0")" && pwd)
cd "$THUB_WORK_DIR" || exit 0
find . -path ./downloads -prune -o -type f -name '*.xml' \( -path '*/results/*' -o -path '*/artifacts/*' \) -print |
while IFS= read -r f; do
  name=$(printf '%s' "${f#./}" | tr '/' '_')
  if printf 'header = "Authorization: Bearer %s"\n' "$ART_TOKEN" | curl -fsS -K - -T "$f" "$base/$name"; then
    sh "$here/artifacts.sh" "$name" "$base/$name" "$f"
  else
    echo "publish-junit: couldn't upload $f" >&2
  fi
done
