#!/usr/bin/env bash
set -euo pipefail

OUT_TEX="out.tex"
PATCHED_TEX="out.patched.tex"
PATCHED_PDF="out.patched.pdf"
FINAL_PDF="Monkey4Business_Brand_Campaign.pdf"
LOG="out.patched.log"

say(){ printf "==> %s\n" "$*"; }

say "0) Cleanup"
rm -f "$OUT_TEX" "$PATCHED_TEX" "$PATCHED_PDF" "$FINAL_PDF" "$LOG" 2>/dev/null || true

say "1) Pandoc -> TeX"
pandoc \
  --metadata-file=meta.yaml \
  -s \
  00_title.md \
  01_brand_campaign_concept.md \
  02_monkey4business_brand_campaign_summary.md \
  03_target_audience_positioning.md \
  04_campaign_materials_implementation.md \
  05_visual_identity_guidelines.md \
  06_research_findings.md \
  -o "$OUT_TEX" \
  --template=custom.tex

say "2) Patch TeX (table hairlines)"
perl ./add-mainrow-rules.pl "$OUT_TEX" "$PATCHED_TEX"

say "3) XeLaTeX (2 runs)"
# Always write a log file (even on failure)
( xelatex -interaction=nonstopmode -halt-on-error "$PATCHED_TEX"; \
  xelatex -interaction=nonstopmode -halt-on-error "$PATCHED_TEX" ) 2>&1 | tee "$LOG" > /dev/null

say "4) Publish PDF"
if [[ -f "$PATCHED_PDF" ]]; then
  mv -f "$PATCHED_PDF" "$FINAL_PDF"
  echo "OK: $FINAL_PDF"
else
  echo "ERROR: $PATCHED_PDF not found. Build failed." >&2
  echo "Last 120 lines of $LOG:" >&2
  tail -n 120 "$LOG" >&2 || true
  exit 1
fi
