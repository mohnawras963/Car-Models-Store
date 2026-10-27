#!/usr/bin/env bash
set -euo pipefail
ARCHIVE="scale-frame-store-store-language-toggle.zip"
if [[ ! -f "$ARCHIVE" ]]; then
  echo "Build error: missing $ARCHIVE in the repository root." >&2
  exit 1
fi
rm -rf .netlify-source public
mkdir -p .netlify-source public
unzip -q "$ARCHIVE" -d .netlify-source
INDEX_PATH="$(find .netlify-source -type f -name index.html -print -quit)"
if [[ -z "$INDEX_PATH" ]]; then
  echo "Build error: index.html was not found inside the ZIP." >&2
  exit 1
fi
SOURCE_DIR="$(dirname "$INDEX_PATH")"
cp -a "$SOURCE_DIR"/. public/
python3 - <<'PY'
from pathlib import Path
import re
p = Path('public/app.js')
if p.exists():
    source = p.read_text(encoding='utf-8')
    source = re.sub(
        r"const contactLink=\$\('#contactLink'\);(?:if\(contactLink\))?contactLink\.href=",
        "const contactLink=$('#contactLink');if(contactLink)contactLink.href=",
        source,
    )
    p.write_text(source, encoding='utf-8')
PY
for file in index.html admin.html styles.css app.js admin.js language.js; do
  if [[ ! -f "public/$file" ]]; then
    echo "Build error: required file public/$file is missing." >&2
    exit 1
  fi
done
node --check public/app.js
node --check public/admin.js
node --check public/language.js
printf '\nBuild OK. Published files:\n'
find public -maxdepth 1 -type f -printf '%f\n' | sort
