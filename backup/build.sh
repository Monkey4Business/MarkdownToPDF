#!/usr/bin/env bash
set -euo pipefail

OUT_PDF="Monkey4Business_Brand_Campaign.pdf"
STAMP="$(date +%Y%m%d_%H%M%S)"
DEBUG_DIR="debugging/$STAMP"
mkdir -p "$DEBUG_DIR"

echo "==> 0) Backup existing out.* into $DEBUG_DIR (if any)"
shopt -s nullglob
for f in out.* out.patched.*; do
  mv -f "$f" "$DEBUG_DIR/" || true
done
shopt -u nullglob

echo "==> 1) Pandoc -> TeX (out.tex)"
pandoc \
  --metadata-file=meta.yaml \
  00_title.md \
  01_brand_campaign_concept.md \
  02_monkey4business_brand_campaign_summary.md \
  03_target_audience_positioning.md \
  04_campaign_materials_implementation.md \
  05_visual_identity_guidelines.md \
  06_research_findings.md \
  -o out.tex \
  --template=custom.tex

test -f out.tex || { echo "ERROR: out.tex was not created."; exit 1; }

echo "==> 2) Patch TeX: table hairlines + Monkey4Business no-break"
cp -f out.tex out.patched.tex

# 2a) Insert subtle row hairlines (uses \m4bhairline from custom.tex)
perl add-mainrow-rules.pl < out.patched.tex > out.patched.tmp.tex
mv -f out.patched.tmp.tex out.patched.tex

# 2b) Enforce NO line break for Monkey4Business everywhere in body text
# (mbox prevents breaks even in headings; hyphenation exception remains as additional safety)
perl -pe 's/(?<!\\\\)Monkey4Business/\\mbox{Monkey4Business}/g' out.patched.tex > out.patched.tmp.tex
mv -f out.patched.tmp.tex out.patched.tex

echo "==> 3) XeLaTeX (2 runs)"
xelatex -interaction=nonstopmode -halt-on-error out.patched.tex > out.patched.log
xelatex -interaction=nonstopmode -halt-on-error out.patched.tex >> out.patched.log

echo "==> 4) Publish final PDF"
if [[ ! -f out.patched.pdf ]]; then
  echo "ERROR: out.patched.pdf not found. Build failed."
  echo "Last 80 lines of out.patched.log:"
  tail -n 80 out.patched.log || true
  exit 1
fi

cp -f out.patched.pdf "$OUT_PDF"
echo "OK: $OUT_PDF updated."

echo "==> 5) Move build artifacts into $DEBUG_DIR (keep final PDF in root)"
mv -f out.tex out.patched.tex out.patched.log out.patched.aux out.patched.out out.patched.toc "$DEBUG_DIR/" 2>/dev/null || true

echo "DONE."