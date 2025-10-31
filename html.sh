#!/bin/bash

if [ -z "$1" ]
then
  DEST_DIR='build'
else
  DEST_DIR="$1"
fi

if [ -z "$2" ]
then
  DOMAIN='nftables.docs.oxl.app'
else
  DOMAIN="$2"
fi

set -euo pipefail

function log() {
  msg="$1"
  echo ''
  echo "### ${msg} ###"
  echo ''
}

cd "$(dirname "$0")"

SRC_DIR="$(pwd)"

TS="$(date +%s)"
# TMP_DIR="/tmp/${TS}"
TMP_DIR="/tmp/nft-test"
TMP_DIR2="${TMP_DIR}/build"
mkdir -p "${TMP_DIR2}"

VENV_BIN='/tmp/.oxl-sphinx-venv/bin/activate'
if [ -f "$VENV_BIN" ]
then
  source "$VENV_BIN"
fi

log 'DOWNLOADING UPSTREAM DOCS'
cd "$TMP_DIR"
rm -f "${SRC_DIR}/source/usage/"*.md "${SRC_DIR}/source/intro/"*.md
download-mediawiki --url 'https://wiki.nftables.org/wiki-nftables' --convert-to-md --out-dir ./dump
cp ./dump/*/*.md "${SRC_DIR}/source/usage/"
cp ./dump/overview.json "${SRC_DIR}/source/"

mv "${SRC_DIR}/source/usage/1.md" "${SRC_DIR}/source/intro/"
mv "${SRC_DIR}/source/usage/2.md" "${SRC_DIR}/source/intro/"
mv "${SRC_DIR}/source/usage/3.md" "${SRC_DIR}/source/intro/"
mv "${SRC_DIR}/source/usage/4.md" "${SRC_DIR}/source/intro/"
#rm -f "${SRC_DIR}/source/usage/README.md"
#rm -f "${SRC_DIR}/source/usage/00scratch.md"
#rm -f "${SRC_DIR}/source/usage/_Sidebar.md"

log 'PATCHING DOCS & UPDATING SITEMAP'
FILE_SM="${TMP_DIR}/sitemap.xml"
cp "${SRC_DIR}/source/_meta/sitemap.xml" "$FILE_SM"
for file in "${SRC_DIR}/source/"*/*.md
do
  # echo " > $file"

  # full links
  # sed -i -r "s|https:\/\/github\.com\/GAM-team\/GAM\/wiki\/([a-zA-Z0-9_\-]*?)|https://${DOMAIN}/usage/\1.html|g" "$file"

  # relative links to other docs
  # sed -i -r "s|\]\(([a-zA-Z0-9_\-]*?)\)|](https://${DOMAIN}/usage/\1.html)|g" "$file"

  # change all but the first H1 to a H2
  # h1="$(grep '^#' < "$file" | head -n 1 || true)"
  # sed -i "s|^#\s|## |g" "$file"
  # sed -i "s|^#$h1|$h1|g" "$file"

  # remove heading-tags
  sed -i -r "s|\s\\{#.*?\\}||g" "$file"

  file_id="$(echo "$file" | rev | cut -d '/' -f 1 | rev | sed 's|.md||g')"
  file_title="$(jq ".[] | .[\"${file_id}\"]? // empty" < "${SRC_DIR}/source/overview.json")"
  file_title_safe="$(echo "$file_title" | sed 's|\s|_|g' | sed 's|"||g' | sed 's|/|_|g')"
  # url-encode
  file_title_safe="$(python3 -c 'import urllib.parse; from sys import argv; print(urllib.parse.quote_plus(argv[1]))' "$file_title_safe")"

  if echo "$file_title" | grep -q ':'
  then
    echo "Removing meta-file: ${file_id} (${file_title})"
    rm "$file"
    continue
  fi

  src_subdir="$(echo "$file" | rev | cut -d '/' -f 2 | rev)"

  file_new="${SRC_DIR}/source/${src_subdir}/${file_title_safe}.md"
  mv "$file" "$file_new"
  echo "  <url><loc>https://${DOMAIN}/${src_subdir}/${file_title_safe}.html</loc></url>" >> "$FILE_SM"

  echo '' >> "$file"
  echo '----' >> "$file"
  echo '' >> "$file"
  # NOTE: edge-case where the original had a '/' in its title will not work correctly
  echo "[Original Documentation](https://wiki.nftables.org/wiki-nftables/index.php/${file_title_safe})" >> "$file_new"
done
echo '</urlset>' >> "$FILE_SM"

log 'BUILDING DOCS'
export PYTHONWARNINGS='ignore'
sphinx-build -b html "${SRC_DIR}/source/" "${TMP_DIR2}/" >/dev/null

log 'PATCHING METADATA'
cp "${SRC_DIR}/source/_meta/"* "${TMP_DIR2}/"
cp "$FILE_SM" "${TMP_DIR2}/"

HTML_META_SRC="<meta charset=\"utf-8\" />"
HTML_META="${HTML_META_SRC}<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'self'; img-src 'self' https://files.oxl.at https://github.com *.s3.amazonaws.com; style-src 'self' https://files.oxl.at 'unsafe-inline'; script-src 'self' https://files.oxl.at 'unsafe-inline' 'unsafe-eval'; connect-src 'self';\">"
HTML_META="${HTML_META}<link rel=\"icon\" type=\"image/webp\" href=\"https://files.oxl.at/img/oxl3_sm.webp\">"
HTML_META_EN="${HTML_META}<link rel=\"alternate\" href=\"https://${DOMAIN}\" hreflang=\"en\">"
HTML_LOGO_LINK_SRC='href=".*Go to homepage"'
HTML_LOGO_LINK_EN='href="https://www.netfilter.org/projects/nftables/index.html" class="oxl-nav-logo" title="NFTables Project"'
HTML_LANG_NONE='<html'
HTML_LANG_EN='html lang="en"'

cd "${TMP_DIR2}/"

sed -i "s|$HTML_META_SRC|$HTML_META_EN|g" *.html
sed -i "s|$HTML_META_SRC|$HTML_META_EN|g" */*.html
sed -i "s|$HTML_LOGO_LINK_SRC|$HTML_LOGO_LINK_EN|g" *.html
sed -i "s|$HTML_LOGO_LINK_SRC|$HTML_LOGO_LINK_EN|g" */*.html
sed -i "s|$HTML_LANG_NONE|<$HTML_LANG_EN|g" *.html
sed -i "s|$HTML_LANG_NONE|<$HTML_LANG_EN|g" */*.html

log 'ACTIVATING'
cd "$SRC_DIR"
if [ -d "$DEST_DIR" ]
then
  rm -r "$DEST_DIR"
fi
mkdir -p "${DEST_DIR}"

mv "${TMP_DIR2}/"* "${DEST_DIR}/"

touch "${DEST_DIR}/${TS}"

rm -rf "$TMP_DIR"

log 'FINISHED'
