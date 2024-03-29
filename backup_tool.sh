#!/bin/bash

current_datetime=$(date "+%Y%m%d_%H%M%S")
default_backup_filename="backup_${current_datetime}.tar.gz"
log_file="/var/log/backup_log_${current_datetime}.log"
backup_filename="${default_backup_filename}"

welcome_message() {
  echo "*****************************************************************************************************"
  echo "                                     Welcome to MyBackupTool!"
  echo "*****************************************************************************************************"
  echo "This tool allows you to perform backups of user-specified directories."
  echo "By default, the compressed backup file will be saved in the current working directory with the name: backup_$current_datetime.tar.gz"
  echo "The log directory will be in (/var/log/)"
  echo "*****************************************************************************************************"
}

log_message() {
 echo "$current_datetime $1" >>"$log_file"
  echo "$1"
}

change_backup_directory() {
  while true; do
    read -p "Do you want to change the directory where the backup file will be saved (defult directory is current folder)? (y/n): " change_dir

    if [ "$change_dir" == "y" ]; then
      read -p "Enter the directory to save the compressed backup file: " custom_dir

      if [ -d "$custom_dir" ]; then
        backup_filename="${custom_dir%/}/${default_backup_filename}"
        break
      else
        read -p "The specified directory does not exist. Do you want to create it? (y/n): " create_dir

        if [ "$create_dir" == "y" ]; then
          mkdir -p "$custom_dir"
          backup_filename="${custom_dir%/}/${default_backup_filename}"
          echo "Directory created: $custom_dir"
          break
        else
          echo "Please enter a valid directory or 'n'."
        fi
      fi
    elif [ "$change_dir" == "n" ]; then
      break
    else
      echo "Invalid input. Please enter 'y' to change the directory or 'n' to continue with the current directory."
    fi
  done
}

perform_backup() {
  while true; do
    read -e -p "Enter the directory path that you want to pack up: " backup_directory
    if [ -d "$backup_directory" ]; then
      log_message "Backup started for directory: $backup_directory"

      tar -cf - "$backup_directory" | pv -s $(du -sb "$backup_directory" | awk '{print $1}') | gzip >"$backup_filename" 2>>"$log_file"

      if [ $? -eq 0 ]; then
        log_message "Backup completed successfully. Backup file: $backup_filename"
        log_message "Size of backup file: $(du -h "$backup_filename" | cut -f1)"
        break
      else
        log_message "Error: Backup failed. See the log for details."
      fi
    else
      log_message "Error: Directory $backup_directory not found. Please enter a valid directory."
    fi
  done
}

main() {
  clear
  welcome_message
  change_backup_directory
  echo "*****************************************************************************************************"
  perform_backup
}

main
