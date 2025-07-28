#!/bin/bash
# Save as ~/find_unimported.sh
while read -r dir; do
  artist=$(basename "$(dirname "$dir")" | sed 's/&/and/g; s/João/Joao/g')
  album=$(basename "$dir" | sed 's/_/ /g')
  if ! grep -i "$artist.*$album" ./imported_albums.txt; then
    echo "$dir"
  fi
done < ./all_albums.txt > ./skipped_albums.txt
