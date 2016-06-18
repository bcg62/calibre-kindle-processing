#!/usr/bin/env bash

[[ -f /etc/defaults/calibre ]] && . /etc/defaults/calibre

: ${DOWNLOADS:="/media/downloads/calibre"}
: ${LIBRARY:="/media/Books"}
: ${CALIBRE_PATH:="/usr/local/bin"}
: ${CACHE_FILE:="/var/cache/polished.books"}
: ${CONVERT_FORMATS:="cbz cbr cbc chm epub fb2 lit lrf odt prc pdb pdf pml rb rtf snb tcr"}
: ${OUTPUT_FORMAT:="azw3"}
: ${PROFILE:="kindle_pw"}

for ext in $CONVERT_FORMATS; do

  while read -r file; do

    [[ -z $file ]] && continue

    output=${file%.*}.$OUTPUT_FORMAT

    [[ -f "$output" ]] &&
    {
      echo "skipping - already exists - $output"
      continue
    }

    $CALIBRE_PATH/ebook-convert "${file}" "${output}" --output-PROFILE $PROFILE;

  done <<<"$(find "$DOWNLOADS" -type f -name "*.$ext")"

done

# skip if downloads is empty
$(ls -1qA ${DOWNLOADS} | grep -q .) &&
{
  echo "updating calibredb"
  $CALIBRE_PATH/calibredb add --with-LIBRARY=${LIBRARY} ${DOWNLOADS}

  echo "embedding metadata"
  $CALIBRE_PATH/calibredb embed_metadata all --with-LIBRARY=${LIBRARY}

  echo "polishing $OUTPUT_FORMAT books"
  while read -r file; do

    [[ -f "$CACHE_FILE" ]] || touch "$CACHE_FILE"

    # skip if ebook is in the cache and has been polished already
    grep -q "$file" "$CACHE_FILE" ||
    {
      $CALIBRE_PATH/ebook-polish \
      --verbose \
      --cover "${file%/*}/cover.jpg" \
      --opf "${file%/*}/metadata.opf" \
      --jacket \
      --remove-unused-css \
      "$file" "$file"

      [[ $? -eq 0 ]] &&
        echo "$file" >> "$CACHE_FILE"
    }

  done <<<"$(find "${LIBRARY}" -type f -name "*.$OUTPUT_FORMAT")"

  echo "cleaning downlaods"
  rm -rfv "${DOWNLOADS}"/*
}
