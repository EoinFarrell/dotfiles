#!/bin/bash

# Define known file paths and their aliases (replace these with your actual paths)
declare -a file_aliases=("file-1" "file-2")
declare -a file_paths=("$DOTFILES/zsh/scripts/copy/file-1" "$DOTFILES/zsh/scripts/copy/file-2")

printAll(){
  input=$1
  search_key=$2
  
  file_path=""
  
  # Check if the input is an alias and get the corresponding file path
  i=0
  j=0
  for fileAlias in "${file_aliases[@]}"; do
      if [[ $input == $fileAlias ]]; then
          for filePath in "${file_paths[@]}"; do
              if [[ $i -eq $j ]]; then
                  file_path=$filePath
              fi
              ((j++))
          done
      fi
      ((i++))
  done
  
  # If the input is not an alias, use it as the file path
  if [ -z "$file_path" ]; then
      file_path=$input
  fi
  
  # Check if the file exists and is readable
  if [ ! -f "$file_path" ]; then
      echo "Error: File $file_path not found."
  elif [ ! -r "$file_path" ]; then
      echo "Error: File $file_path is not readable."
  else 
    cat $file_path
  fi
}

findOrg(){
  input=$1
  search_key=$2
  
  file_path=""
  
  # Check if the input is an alias and get the corresponding file path
  i=0
  j=0
  for fileAlias in "${file_aliases[@]}"; do
      if [[ $input == $fileAlias ]]; then
          for filePath in "${file_paths[@]}"; do
              if [[ $i -eq $j ]]; then
                  file_path=$filePath
              fi
              ((j++))
          done
      fi
      ((i++))
  done
  
  # If the input is not an alias, use it as the file path
  if [ -z "$file_path" ]; then
      file_path=$input
  fi
  
  # Check if the file exists and is readable
  if [ ! -f "$file_path" ]; then
      echo "Error: File $file_path not found."
  elif [ ! -r "$file_path" ]; then
      echo "Error: File $file_path is not readable."
  else
    # Search for the key-value pair in the file
    value=$(grep -w "^$search_key" "$file_path" | awk -F':' '{print $2}' | tr -d '[:space:]')
    
    # Check if the key was found and print the result
    if [ -z "$value" ]; then
        echo "Key not found: $search_key"
    else
        echo "Value for $search_key: $value"
        echo -n "$value" | pbcopy  # Copy the value to the clipboard
        echo "Value copied to clipboard."
    fi
  fi
}

if [ $# -eq 1 ]; then
    printAll $1
elif [ $# -eq 2 ]; then
    findOrg $1 $2
else
    echo "Usage: $0 <file_alias|file_path>"
    echo "Usage: $0 <file_alias|file_path> <search_key>"
fi