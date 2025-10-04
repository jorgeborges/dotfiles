#!/bin/bash

# Ensure the Slack webhook URL is set in the environment.
if [ -z "$PULSEOWL_ALERT_APP_WEBHOOK_URL" ]; then
    echo "#[fg=red]PO-ECS ERR: Webhook not set"
    exit 1
fi

# Ensure the state file is set in the environment.
if [ -z "$ECS_TASKCOUNT_MONITOR_STATE_FILE" ]; then
    echo "#[fg=red]PO-ECS ERR: State file not set"
    exit 1
fi

task_count=$(aws ecs list-tasks --profile "$AWS_PROFILE_PULSEOWL_MONITOR" --cluster "$AWS_CLUSTER_PULSEOWL_MONITOR" --desired-status RUNNING | jq '.taskArns | length')

# Check if task_count is a valid integer
if ! [[ "$task_count" =~ ^[0-9]+$ ]]; then
    echo "#[fg=red]PO-ECS ERR"
    osascript -e 'display notification "Failed to get ECS task count." with title "PulseOwl ECS Monitor Error"'
    exit 1
fi

# Decide alert state and messages
if [ "$task_count" -ge 7 ]; then
    alert_state="ALERT"
    alert_msg=":red_circle: *ALERT!* ECS running task count is *$task_count* (>6) in PulseOwl cluster."
    echo "#[fg=red]ALERT! PO-ECS: $task_count > 6"
elif [ "$task_count" -ge 2 ]; then
    alert_state="OK"
    alert_msg=":white_check_mark: ECS running task count back to normal: $task_count."
    echo "#[fg=green]PO-ECS($task_count) "
else
    alert_state="WARNING"
    alert_msg=":warning: *WARNING!* ECS running task count is low: $task_count (<2)."
    echo "#[fg=yellow]WARNING! PO-ECS: $task_count < 2"
fi

# Read last alert state, if file exists
last_state=""
if [ -f "$ECS_TASKCOUNT_MONITOR_STATE_FILE" ]; then
    last_state=$(cat "$ECS_TASKCOUNT_MONITOR_STATE_FILE")
fi

# Send to Slack *only if state has changed*
if [ "$alert_state" != "$last_state" ]; then
    curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$alert_msg\"}" "$PULSEOWL_ALERT_APP_WEBHOOK_URL" > /dev/null
fi

# Save current state for next run
echo "$alert_state" > "$ECS_TASKCOUNT_MONITOR_STATE_FILE"
