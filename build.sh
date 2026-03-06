#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="backup"
DATE_PREFIX=$(date +"%Y-%m-%d")
DEBUG_DIR="debug/$DATE_PREFIX"
OUT_TEX="out.tex"
PATCHED_AUX="out.patched.aux"
PATCHED_OUT="out.patched.out"
PATCHED_PDF="out.patched.pdf"
PATCHED_TEX="out.patched.tex"
PATCHED_TOC="out.patched.toc"
LOG="out.patched.log"
FINAL_PDF="Monkey4Business_Brand_Campaign.pdf"

say() {
  printf "==> %s\n" "$*"
}

fail() {
  echo "ERROR: $*" >&2
  if [[ -f "$LOG" ]]; then
    echo "Last 120 lines of $LOG:" >&2
    tail -n 120 "$LOG" >&2 || true
  fi
  exit 1
}

move_if_exists() {
  local f="$1"
  if [[ -f "$f" ]]; then
    mv -f "$f" "$DEBUG_DIR/"
    echo "Moved $f -> $DEBUG_DIR/"
  else
    echo "Skip (not found): $f"
  fi
}

say "0) Backup old Monkey4Business_Brand_Campaign.pdf and Cleanup old outputs"
mkdir -p "$BACKUP_DIR"
mkdir -p "$DEBUG_DIR"

if [[ -f "$FINAL_PDF" ]]; then
  BACKUP_FILE="${DATE_PREFIX}_${FINAL_PDF}"

  echo "Backing up existing PDF -> $BACKUP_DIR/$BACKUP_FILE"
  mv "$FINAL_PDF" "$BACKUP_DIR/$BACKUP_FILE"
fi

rm -f "$OUT_TEX" "$PATCHED_AUX" "$PATCHED_OUT" "$PATCHED_PDF" "$PATCHED_TEX" "$PATCHED_TOC" "$LOG" "$FINAL_PDF" 2>/dev/null || true

say "1) Pandoc -> TeX"
pandoc \
  --metadata-file=buildfiles/meta.yaml \
  -s \
  content/00_title.md \
  content/01_brand_campaign_concept.md \
  content/02_monkey4business_brand_campaign_summary.md \
  content/03_target_audience_positioning.md \
  content/04_campaign_materials_implementation.md \
  content/05_visual_identity_guidelines.md \
  content/06_research_findings.md \
  -o "$OUT_TEX" \
  --template=buildfiles/custom.tex || fail "Pandoc failed"

[[ -f "$OUT_TEX" ]] || fail "$OUT_TEX was not created"

say "2) Patch TeX (table hairlines)"
perl buildfiles/add-mainrow-rules.pl "$OUT_TEX" "$PATCHED_TEX" || fail "Perl patcher failed"

[[ -f "$PATCHED_TEX" ]] || fail "$PATCHED_TEX was not created"

say "3) XeLaTeX (2 runs)"
xelatex -interaction=nonstopmode -halt-on-error "$PATCHED_TEX" > "$LOG" 2>&1 || fail "XeLaTeX run #1 failed"
xelatex -interaction=nonstopmode -halt-on-error "$PATCHED_TEX" >> "$LOG" 2>&1 || fail "XeLaTeX run #2 failed"

[[ -f "$PATCHED_PDF" ]] || fail "$PATCHED_PDF was not created"

say "4) Publish final PDF"
cp -f "$PATCHED_PDF" "$FINAL_PDF" || fail "Could not copy final PDF"

[[ -f "$FINAL_PDF" ]] || fail "$FINAL_PDF was not created"

say "5) Move build artifacts to $DEBUG_DIR"
move_if_exists "$OUT_TEX"
move_if_exists "$PATCHED_AUX"
move_if_exists "$PATCHED_OUT"
move_if_exists "$PATCHED_PDF"
move_if_exists "$PATCHED_TEX"
move_if_exists "$PATCHED_TOC"
move_if_exists "$LOG"

say "DONE: $FINAL_PDF"