#!/bin/sh
# Builds the GitHub Pages site: the skin test demo wrapped in a full HTML document.
set -e
out=${1:-_site}
mkdir -p "$out"
{
  printf '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><style>:root{color-scheme:light}body{margin:0;font:14px system-ui}[hidden]{display:none!important}</style></head><body>\n'
  cat demos/skin-test/index.html
  printf '\n</body></html>\n'
} > "$out/index.html"
touch "$out/.nojekyll"
