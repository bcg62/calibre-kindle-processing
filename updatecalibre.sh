#!/usr/bin/env bash

[[ -f /etc/defaults/calibre ]] && . /etc/defaults/calibre

: ${DOWNLOADS:="/media/downloads/calibre"}
: ${LIBRARY:="/media/Books"}
: ${CALIBRE_PATH:="/usr/local/bin"}
: ${CACHE_FILE:="/var/cache/polished.books"}
: ${CONVERT_FORMATS:="cbz cbr cbc chm epub fb2 lit lrf odt mobi prc pdb pdf pml rb rtf snb tcr"}
: ${OUTPUT_FORMAT:="azw3"}
: ${PROFILE:="kindle_pw"}

[[ -f "$CACHE_FILE" ]] || touch "$CACHE_FILE"

for ext in $CONVERT_FORMATS; do

  while read -r file; do

    [[ -z $file ]] && continue

    output="${file%.*}.$OUTPUT_FORMAT"

    [[ -f "$output" ]] &&
    {
      echo "skipping - already exists - $output"
      continue
    }

    "$CALIBRE_PATH"/ebook-convert \
    "${file}" "${output}" \
    --output-profile $PROFILE;

  done <<<"$(find "$DOWNLOADS" -type f -name "*.$ext")"

done

# skip if downloads is empty
$(ls -1qA ${DOWNLOADS} | grep -q .) &&
{
  echo "updating calibredb"
  "$CALIBRE_PATH"/calibredb add --with-library=${LIBRARY} ${DOWNLOADS}

  while read -r file; do

    # get calibre db id numebr
    calibre_id=$(sed -n 's:.*d="calibre_id">\(.*\)<.*:\1:p' "${file%/*}/metadata.opf")

    [[ -z $calibre_id ]] &&
    {
      echo "could not find calibre_id for $file"
      continue
    }

    # skip if ebook is in the cache and has been polished already
    grep -q "^${calibre_id}$" "$CACHE_FILE" ||
    {

      title=$(
        "$CALIBRE_PATH"/calibredb \
        show_metadata $calibre_id \
        --with-library=${LIBRARY} |
        sed -n 's/^Title[[:blank:]]*: \(.*\).*/\1/p'
      )

      authors=$(
        "$CALIBRE_PATH"/calibredb \
        show_metadata $calibre_id \
        --with-library=${LIBRARY} |
        sed -n 's/^Author(s)[[:blank:]]*: \(.*\).*/\1/p'
      )

     isbn=$(
       "$CALIBRE_PATH"/calibredb \
        show_metadata $calibre_id \
        --with-library=/media/Books |
        sed -n 's/.*isbn:\([0-9]*\).*/\1/p'
     )

      echo "fetching new metadata and cover for ${title}"
      metadata=$(
        "$CALIBRE_PATH"/fetch-ebook-metadata \
        --title="$title" \
        --authors="$authors" \
        --isbn="$isbn" \
        --cover "${file%/*}/cover.jpg" \
        --opf
      )

      [[ $? -ne 0 ]] &&
      {
        echo "failed to fetch metadata for ${title}"
        continue
      }

      echo "$metadata" > "${file%/*}/metadata.opf"

      echo "updatding calibredb with new metadata"
      "$CALIBRE_PATH"/calibredb \
      set_metadata $calibre_id \
      --with-library=${LIBRARY} \
      "${file%/*}/metadata.opf"

      echo "embedding new metadata into $file"
      "$CALIBRE_PATH"/calibredb \
      embed_metadata $calibre_id \
      --with-library=${LIBRARY} \

      echo "polishing $OUTPUT_FORMAT for ${title}"
      $CALIBRE_PATH/ebook-polish \
      --verbose \
      --cover "${file%/*}/cover.jpg" \
      --opf "${file%/*}/metadata.opf" \
      --jacket \
      --remove-unused-css \
      "$file" "$file"

      [[ $? -eq 0 ]] &&
        echo "$calibre_id" >> "$CACHE_FILE"
    }

  done <<<"$(find "${LIBRARY}" -type f -name "*.$OUTPUT_FORMAT")"

  echo "cleaning downlaods"
  rm -rfv "${DOWNLOADS}"/*
}
