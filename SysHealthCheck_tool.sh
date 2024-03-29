#!/bin/bash

check_disk_space() {
  log_message "Checking Disk Space..."
  percentage2check=70
  sleep 1

  df_output=$(df -h)

  log_message "Disk Space Usage:"
  log_message "$df_output"
  log_message "*****************************************************************************"
  read -p "the default danger percentage of disk usage is 70%, do you want to change that? (y/n)" user_response

  if [ "$user_response" == "y" ]; then
   while true; do
    read -p "Enter a new value of percentage: " new_value

      if is_positive_integer "$new_value"; then
          percentage2check="$new_value"
          log_message "Value of percentage2check updated to: $percentage2check%"
          break  
      else
          echo "Invalid input. Please enter a positive integer."
      fi
    done
    
  else
    log_message "Using the default value of percentage to check: $percentage2check"
  fi

  echo "based on your disk these are the recommended actions"
  while read -r filesystem size used avail percentage mountpoint; do

    if [[ "$filesystem" == "Filesystem" ]]; then
      continue
    fi
    if [ ${percentage%\%} -gt "$percentage2check" ]; then
      log_message "Disk $filesystem is almost full. Usage: $percentage"
      log_message "you have only $avail left"
      log_message "you better clean some space"
      echo "*****************************************************************************"
    fi
  done <<<"$df_output"
  log_message "the rest of the disks are fine"
  log_message "checking disk space useage done"
  log_message "*****************************************************************************"
}

check_memory_usage() {
  echo "*****************************************************************************"
  percentage2check=70
  log_message "Checking Memory Usage..."
  sleep 0.4
  memory=$(free -m)
  free_memory=$(echo "$memory" | awk '/^Mem/ {print $4}')
  used_memory=$(echo "$memory" | awk '/^Mem/ {print $3}')
  total_memory=$(echo "$memory" | awk '/^Mem/ {print $2}')
  used_memory_percent=$(echo "$used_memory $total_memory" | awk '{ printf "%.0f", ($1 / $2) * 100 }')
  log_message "$memory"
  log_message "*****************************************************************************"

  log_message "Free Memory: $free_memory MB"
  log_message "Used Memory: $used_memory MB"
  log_message "Total Memory: $total_memory MB"
  log_message "Used Memory percentage: $used_memory_percent%"

  case $used_memory_percent in
  [0-9])
    log_message "Memory usage is very low. Free Memory: $free_memory MB, Used Memory: $used_memory MB, Total Memory: $total_memory MB, Used Memory percent: $used_memory_percent%"
    ;;
  [0-4][0-9])
    log_message "Memory usage is low. Free Memory: $free_memory MB, Used Memory: $used_memory MB, Total Memory: $total_memory MB, Used Memory percent: $used_memory_percent%"
    ;;
  [5-7][0-9])
    log_message "Memory usage is moderate. Free Memory: $free_memory MB, Used Memory: $used_memory MB, Total Memory: $total_memory MB, Used Memory percent: $used_memory_percent%"
    ;;
  [8-9][0-9])
    log_message "Memory usage is high. Free Memory: $free_memory MB, Used Memory: $used_memory MB, Total Memory: $total_memory MB, Used Memory percent: $used_memory_percent%"
    ;;
  *)
    echo "Invalid memory percentage."
    ;;
  esac

  read -p "the default danger percentage of memory usage is 70%, do you want to change that? (y/n)" user_response

  if [ "$user_response" == "y" ]; then

    while true; do
        read -p "Enter a new value for free momory percentage: " new_value
        if is_positive_integer "$new_value"; then
        percentage2check="$new_value"
        log_message "Value of percentage2check updated to: $percentage2check%"
            break 
        else
            echo "Invalid input. Please enter a positive integer."
        fi
    done
  else
    log_message "Using the default value of percentage to check: $percentage2check%"
  fi

  if [ "$used_memory_percent" -gt "$percentage2check" ]; then
    log_message "WARNING: Low free memory! Consider optimizing or adding more RAM."
    log_message "Memory usage is more than $percentage2check%. Listing top 4 processes by memory usage:"
    ps aux --sort=-%mem | head -n 5
    log_message "we recomand you to stop the unnecessary ones"
    log_message "you can do that by trying this comand : kill -(the processe id here) PID"
    log_message "but be carefull with that" 
    else
    log_message "The memory usage is good you don't have to do anything"
  fi
  log_message "checking memory usage done."
}

check_running_services() {
  log_message "*****************************************************************************"
  log_message "Checking Running Services..."
  sleep 0.4

  log_message "a list of the running services:"
  running_services=$(systemctl list-units --type=service --state=running)
  log_message "$running_services"
  log_message "We recommend updating and patching the services"

  read -p "Do you want to update the services? (y/n): " choice
  if [ "$choice" == "y" ]; then
    update_and_patch_services
  else
    log_message "the services will not be updated"
  fi
  log_message "checking running services done."
}

update_and_patch_services() {
  log_message "*****************************************************************************"
  log_message "Updating and Patching Services..."

  if [ -x "$(command -v apt-get)" ]; then

    sudo apt-get update | pv -W >/dev/null
    upgrade_output=$(sudo apt-get upgrade -s)
    log_message "upgrade_output => $upgrade_output"
    available_updates=$(echo "$upgrade_output" | awk '/^Inst/ {print $2}')

    if [ -n "$available_updates" ]; then
      log_message "Available Updates: $available_updates"
      read -p "are you sure you want to update these services? (y/n): " choice
      if [ "$choice" == "y" ]; then
        sudo apt-get upgrade -y
        log_message "Services updated successfully."
      else
        log_message "Update skipped as per user choice."
      fi
    else
      log_message "No updates available for services."
    fi
  else
    log_message "Unsupported package manager. Update check skipped."
  fi
}

check_system_updates() {
  echo "*****************************************************************************"
  log_message "Checking Recent System Updates..."

  while true; do

    read -p "How many updates do you want to show? " num_of_updates
    if is_positive_integer "$num_of_updates"; then

      latest_system_updates=$(sudo cat /var/log/apt/history.log | grep "Install\|Upgrade" | head -n "$num_of_updates" | awk -F'[()]' '{print "-" $2 "--> (" $4 ")"}')
      log_message "$latest_system_updates"
      log_message "Recommendation: We strongly advise updating all system files to ensure your system is up-to-date with the latest security patches and improvements."
      log_message "To perform the update, you can use the following command:"
      log_message "sudo apt update && sudo apt upgrade"
      log_message "This will update your system with the latest packages and enhance its security. Thank you for keeping your system up-to-date!"
      echo "*****************************************************************************"
      break
    else
      echo "Invalid input. Please enter a positive integer."
    fi
  done
 log_message "checking system updates done."
}

log_message() {
    echo "$(date +"[%Y-%m-%d %H:%M:%S]") $1" >> "$log_file"
    echo "$1"
}

welcome_message() {
    echo "Welcome to System Health Check Tool"
    echo "*****************************************************************************"
    echo "This tool will run some commands to check the health of your system."
    echo "This tool has created a log file for the health report in your current directory."
    echo "the log file will be filled throughout the Run of the tool."
    echo "It will perform the following checks:"
    echo "  - Check Disk Space"
    echo "  - Check Memory Usage"
    echo "  - Check Running Services"
    echo "  - Check System Updates"
    echo ""
    read -p "Press Enter to start the tool..."
}

create_logfile(){
    log_file="system_health_log.txt"
    touch "$log_file"
}

is_positive_integer() {
    [[ $1 =~ ^[1-9][0-9]*$ ]]
}

main() {
    clear
    create_logfile
    echo "System Health Report"
    welcome_message
    check_disk_space
    read -p "Press Enter to start memory check..."
    check_memory_usage 
    read -p "Press Enter to start services check..."
    check_running_services 
    read -p "Press Enter to start system update check..."
    check_system_updates 
    
    echo "Health check complete."
}
main