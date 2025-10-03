#!/bin/bash

task_count=$(aws ecs list-tasks --profile "$AWS_PROFILE_PULSEOWL_MONITOR" --cluster "$AWS_CLUSTER_PULSEOWL_MONITOR" --desired-status RUNNING | jq '.taskArns | length')

if ! [[ "$task_count" =~ ^[0-9]+$ ]]; then
    echo "#[fg=red]PO-ECS ERR"
    osascript -e 'display notification "Failed to get ECS task count." with title "PulseOwl ECS Monitor Error"'
    exit 1
fi

if [ "$task_count" -ge 7 ]; then
  echo "#[fg=red]ALERT! PO-ECS > 6"
  osascript -e "display notification \"Task count is $task_count.\" with title \"ALERT! High PulseOwl ECS Tasks\""
elif [ "$task_count" -ge 2 ]; then
  echo "#[fg=green]PO-ECS "
else
  echo "#[fg=yellow]WARNING! PO-ECS < 2"
  osascript -e "display notification \"Task count is $task_count.\" with title \"WARNING! Low PulseOwl ECS Tasks\""
fi
