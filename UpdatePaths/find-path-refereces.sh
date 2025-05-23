#!/bin/bash
# Output each file that needs path updates, one per line

# Get renamed files from the last commit
RENAMED_FILES=$(git diff --name-status --diff-filter=R HEAD^ HEAD 2>/dev/null | awk '{print $2 ":" $3}')

# Try alternative detection if needed
if [ -z "$RENAMED_FILES" ]; then
  DELETED_FILES=$(git diff --name-status --diff-filter=D HEAD^ HEAD 2>/dev/null | awk '{print $2}')
  ADDED_FILES=$(git diff --name-status --diff-filter=A HEAD^ HEAD 2>/dev/null | awk '{print $2}')
  
  for deleted in $DELETED_FILES; do
    filename=$(basename "$deleted")
    for added in $ADDED_FILES; do
      if [ "$(basename "$added")" == "$filename" ]; then
        RENAMED_FILES+="$deleted:$added "
      fi
    done
  done
fi

if [ -z "$RENAMED_FILES" ]; then
  echo "No renamed files found." >&2
  exit 0
fi

echo "$RENAMED_FILES" | while IFS=':' read -r old_path new_path; do
  echo "$old_path → $new_path" >&2
  
  # Check if moved file has relative paths
  if [ -f "$new_path" ]; then
    has_paths=$(grep -l "\.\./\|\./\|[^/]\+/" "$new_path" 2>/dev/null || true)
    if [ ! -z "$has_paths" ]; then
      echo "$new_path"
      grep -n "\.\./\|\./\|[^/]\+/" "$new_path" | head -2 >&2
    fi
  fi
  
  # Find files referencing the old path
  find . -type f -not -path "*/\.git/*" | xargs grep -l "$old_path" 2>/dev/null
done | sort -u
