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

if [ -z "$SKIP_DL" ]
then
  SKIP_DL='0'
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
if [[ "$SKIP_DL" == "0" ]]
then
  TMP_DIR="/tmp/${TS}"
else
  TMP_DIR="/tmp/nft-test"
fi
TMP_DIR2="${TMP_DIR}/build"
mkdir -p "${TMP_DIR2}"

VENV_BIN='/tmp/.oxl-sphinx-venv/bin/activate'
if [ -f "$VENV_BIN" ]
then
  source "$VENV_BIN"
fi

log 'DOWNLOADING UPSTREAM DOCS'
cd "$TMP_DIR"
rm -f "${SRC_DIR}/source/usage/"*.rst "${SRC_DIR}/source/intro/"*.rst
if [[ "$SKIP_DL" == "0" ]] || [ ! -f './dump/overview.json' ]
then
  download-mediawiki --url 'https://wiki.nftables.org/wiki-nftables' --out-dir ./dump
fi

log 'CONVERTING'

# special cases
tail -n +2 ./dump/0/2.mw > ./dump/0/2.mw  # remove duplicate heading

for file in ./dump/*/*.mw
do
  # changing table-format so the conversion works
  # sed -i -r 's/!(\s|)colspan="4"(\s|)\|(.*)$/|\3\n|\n|\n|/g' "$file"
  # sed -i -r 's/!(\s|)colspan="5"(\s|)\|(.*)$/|\3\n|\n|\n|\n|/g' "$file"
  # sed -i -r 's/!(\s|)colspan="6"(\s|)\|(.*)$/|\3\n|\n|/g' "$file"  # not sure why 6.. there are only 3
  # sed -i -r 's/!(\s|)colspan="7"(\s|)\|(.*)$/|\3\n|\n|\n|\n|\n|\n|/g' "$file"
  # sed -i -r 's/!(\s|)colspan="8"(\s|)\|(.*)$/|\3\n|\n|\n|\n|\n|\n|\n|/g' "$file"

  # make sure we only have 1 H1-tag
  h1="$(grep -E '^={1,10} .* ={1,10}$' < "$file" | head -n1 || true)"
  sed -i -r "s|^(={1,10}.*={1,10})$|=\1=|g" "$file"
  sed -i "s|^=$h1=|$h1|g" "$file"

  file_base="$(echo "$file" | sed 's|.mw||g')"
  # pandoc --from mediawiki --to markdown "$file" -o "${file_base}.md"
  pandoc --from mediawiki --columns=500 --to rst "$file" -o "${file_base}.rst"
done

cp ./dump/*/*.rst "${SRC_DIR}/source/usage/"
cp ./dump/overview.json "${SRC_DIR}/source/"

mv "${SRC_DIR}/source/usage/1.rst" "${SRC_DIR}/source/intro/"
mv "${SRC_DIR}/source/usage/2.rst" "${SRC_DIR}/source/intro/"
mv "${SRC_DIR}/source/usage/3.rst" "${SRC_DIR}/source/intro/"
mv "${SRC_DIR}/source/usage/4.rst" "${SRC_DIR}/source/intro/"

log 'PATCHING DOCS & UPDATING SITEMAP'
rm -f "${SRC_DIR}/source/usage/Flowtable.rst"  # empty redirect

FILE_SM="${TMP_DIR}/sitemap.xml"
cp "${SRC_DIR}/source/_meta/sitemap.xml" "$FILE_SM"
for file in "${SRC_DIR}/source/"*/*.rst
do
  if echo "$file" | grep -q '/legal/'
  then
    continue
  fi

  echo " > $file"

  # remove heading-tags
  # sed -i -r "s|\s\\{#.*?\\}||g" "$file"

  file_id="$(echo "$file" | rev | cut -d '/' -f 1 | rev | sed 's|.rst||g')"
  file_title="$(jq ".[] | .[\"${file_id}\"]? // empty" < "${SRC_DIR}/source/overview.json")"
  file_title_safe="$(echo "$file_title" | sed 's|\s|_|g' | sed 's|"||g' | sed 's|/|_|g')"
  # url-encode
  file_title_safe="$(python3 -c 'import urllib.parse; from sys import argv; print(urllib.parse.quote_plus(argv[1]))' "$file_title_safe")"

  if echo "$file_title" | grep -q ':'
  then
    echo " > Removing meta-file: ${file_id} (${file_title})"
    rm "$file"
    continue
  fi

  src_subdir="$(echo "$file" | rev | cut -d '/' -f 2 | rev)"

  file_new="${SRC_DIR}/source/${src_subdir}/${file_title_safe}.rst"
  mv "$file" "$file_new"
  echo "  <url><loc>https://${DOMAIN}/${src_subdir}/${file_title_safe}.html</loc></url>" >> "$FILE_SM"

  # change all but the first H1 to a H2
  # h1="$(grep '^#' < "$file_new" | head -n 1 || true)"
  # sed -i "s|^#\s|## |g" "$file_new"
  # sed -i "s|^#$h1|$h1|g" "$file_new"

  # remove random
  # sed -i 's|{=html}\*||g' "$file_new"

  echo '' >> "$file_new"
  echo '----' >> "$file_new"
  echo '' >> "$file_new"
  # NOTE: edge-case where the original had a '/' in its title will not work correctly
  echo "\`Original Documentation <https://wiki.nftables.org/wiki-nftables/index.php/${file_title_safe}>\`_" >> "$file_new"
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

if [[ "$SKIP_DL" == "0" ]]
then
  rm -rf "$TMP_DIR"
fi

log 'FINISHED'
