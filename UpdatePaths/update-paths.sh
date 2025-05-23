#!/bin/bash
# Read file paths from stdin and interactively update paths

# Get renamed files info
RENAMED_FILES=$(git diff --name-status --diff-filter=R HEAD^ HEAD 2>/dev/null | awk '{print $2 ":" $3}')

# Get repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

while read -r file; do
  [ -z "$file" ] || [ ! -f "$file" ] && continue
  
  echo -e "\nFile: $file" >&2
  
  # Extract and display lines with paths
  path_lines=$(grep -n "\.\./\|\./\|[^/]\+/" "$file" 2>/dev/null | head -3)
  echo "$path_lines" >&2
  
  # Preview path changes
  echo "Preview of changes:" >&2
  echo "$RENAMED_FILES" | while IFS=':' read -r old_path new_path; do
    if [ "$file" = "$new_path" ]; then
      # Process each relative path in the file
      grep -o "\`\?\.\./[^\"')\` ]\+" "$file" 2>/dev/null | sed 's/\`//g' | sort -u | while read -r rel_path; do
        # Extract filename and relative directory
        rel_target_file=$(basename "$rel_path")
        rel_target_dir=$(dirname "$rel_path")
        
        # Calculate depth change for directory
        old_dir=$(dirname "$old_path")
        new_dir=$(dirname "$new_path")
        old_depth=$(echo "$old_dir" | tr -cd '/' | wc -c)
        new_depth=$(echo "$new_dir" | tr -cd '/' | wc -c)
        diff=$((new_depth - old_depth))
        
        # Show current path
        echo "  Current: $rel_path" >&2
        
        # Try to find the actual file in the repository
        actual_path=""
        if [ ! -z "$REPO_ROOT" ]; then
          # First check if it's in the system-prompts directory, since that's mentioned in your login
          system_prompt_path="$REPO_ROOT/system-prompts/$rel_target_file"
          if [ -f "$system_prompt_path" ]; then
            actual_path="$system_prompt_path"
          else
            # Use find to locate the file by name
            find_results=$(find "$REPO_ROOT" -name "$rel_target_file" -type f 2>/dev/null | grep -v "node_modules" | grep -v "\.git/" | head -1)
            if [ ! -z "$find_results" ]; then
              actual_path="$find_results"
            fi
          fi
          
          if [ ! -z "$actual_path" ]; then
            echo "  Found file at: $actual_path" >&2
          fi
        fi
        
        # Calculate new relative path
        if [ ! -z "$actual_path" ]; then
          # This is the case where we found the actual file
          actual_path_relative=$(realpath --relative-to="$(dirname "$file")" "$actual_path" 2>/dev/null || 
                                 python3 -c "import os.path; print(os.path.relpath('$actual_path', '$(dirname "$file")'))")
          echo "  New (found file): $actual_path_relative" >&2
          new_rel="$actual_path_relative"
        elif [ $diff -gt 0 ]; then
          # Standard path depth adjustment
          new_rel="../"
          for i in $(seq 1 $diff); do
            new_rel="../$new_rel"
          done
          # Keep the original filename part
          new_rel="$new_rel$(echo "$rel_path" | sed 's|\.\./||')"
          echo "  New (depth adjusted): $new_rel" >&2
        else
          new_rel="$rel_path"
          echo "  New (unchanged): $new_rel" >&2
        fi
        
        # Try to resolve the absolute path
        curr_dir=$(dirname "$file")
        resolved_path=$(cd "$curr_dir" 2>/dev/null && realpath -m "$new_rel" 2>/dev/null || echo "(Cannot resolve)")
        echo "  Resolves to: $resolved_path" >&2
        
        # Check if the resolved path exists
        if [ -e "$resolved_path" ]; then
          echo "  Status: ✅ File exists" >&2
        else
          echo "  Status: ❌ File not found" >&2
        fi
        echo >&2
        
        # Store the mapping of old path to new path for update phase
        echo "$rel_path:$new_rel" >> /tmp/path_updates_$$.tmp
      done
    fi
    
    # Show direct references that will be updated
    if grep -q "$old_path" "$file" 2>/dev/null; then
      echo "  Will update: $old_path → $new_path" >&2
    fi
  done
  
  # Prompt for action
  echo -e "\nUpdate this file? (y/n/q): \c" >&2
  read choice < /dev/tty
  
  case "$choice" in
    y|Y)
      cp "$file" "${file}.bak"
      
      # Update the mapped paths
      if [ -f "/tmp/path_updates_$$.tmp" ]; then
        while IFS=':' read -r old_rel_path new_rel_path; do
          # Escape special characters for sed/perl
          old_esc=$(echo "$old_rel_path" | sed 's/[\/&]/\\&/g')
          new_esc=$(echo "$new_rel_path" | sed 's/[\/&]/\\&/g')
          
          # Update the path references
          perl -pi -e "s|$old_esc|$new_esc|g" "$file"
        done < "/tmp/path_updates_$$.tmp"
        
        rm -f "/tmp/path_updates_$$.tmp"
      fi
      
      # Update direct references to renamed files
      echo "$RENAMED_FILES" | while IFS=':' read -r old_path new_path; do
        # Escape special characters
        old_esc=$(echo "$old_path" | sed 's/[\/&]/\\&/g')
        new_esc=$(echo "$new_path" | sed 's/[\/&]/\\&/g')
        
        # Update direct references
        perl -pi -e "s|$old_esc|$new_esc|g" "$file"
      done
      
      # Use colordiff if available, otherwise fall back to regular diff
      echo "Updated. Changes:" >&2
      if command -v colordiff >/dev/null 2>&1; then
        colordiff -u "${file}.bak" "$file" | head -10 >&2
      else
        diff -u "${file}.bak" "$file" | head -10 >&2
      fi
      ;;
    q|Q) 
      rm -f "/tmp/path_updates_$$.tmp" 2>/dev/null
      echo "Exiting." >&2
      exit 0 ;;
    *) 
      rm -f "/tmp/path_updates_$$.tmp" 2>/dev/null
      echo "Skipped." >&2 ;;
  esac
done

# Clean up any temporary files
rm -f "/tmp/path_updates_$$.tmp" 2>/dev/null
