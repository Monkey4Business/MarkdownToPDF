#!/bin/bash
set -e

# 1) Pandoc -> TeX
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
  --template=custom.tex \
  --pdf-engine=xelatex

# 2) Patch: insert main-row rules
perl add-mainrow-rules.pl < out.tex > out.patched.tex

# 3) Compile patched TeX -> PDF (2 runs for refs/toc)
xelatex -interaction=nonstopmode out.patched.tex
xelatex -interaction=nonstopmode out.patched.tex

# 4) Rename output
cp -f out.patched.pdf Monkey4Business_Brand_Campaign.pdf