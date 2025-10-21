#!/bin/bash

# The script will only perform a full check once per this interval (in seconds)
EXECUTION_INTERVAL=300

# --- Rate-Limiting Logic ---
# Ensure cache file paths are set in the environment.
if [ -z "$ECS_TASKCOUNT_MONITOR_LAST_RUN_FILE" ] || [ -z "$ECS_TASKCOUNT_MONITOR_LAST_OUTPUT_FILE" ]; then
    echo "#[fg=red]PO-ECS ERR: Cache files not set"
    exit 1
fi

current_time=$(date +%s)
last_run_time=0
if [ -f "$ECS_TASKCOUNT_MONITOR_LAST_RUN_FILE" ]; then
    last_run_time=$(cat "$ECS_TASKCOUNT_MONITOR_LAST_RUN_FILE")
fi

time_since_last_run=$((current_time - last_run_time))

# If the interval has not passed and we have a cached output, show it and exit.
if [ "$time_since_last_run" -lt "$EXECUTION_INTERVAL" ] && [ -f "$ECS_TASKCOUNT_MONITOR_LAST_OUTPUT_FILE" ]; then
    cat "$ECS_TASKCOUNT_MONITOR_LAST_OUTPUT_FILE"
    exit 0
fi

# --- Main Monitoring Logic ---

# Ensure other environment variables are set.
if [ -z "$PULSEOWL_ALERT_APP_WEBHOOK_URL" ] || [ -z "$ECS_TASKCOUNT_MONITOR_STATE_FILE" ]; then
    tmux_output="#[fg=red]PO-ECS ERR: ENV not set"
    echo "$current_time" > "$ECS_TASKCOUNT_MONITOR_LAST_RUN_FILE"
    echo "$tmux_output" > "$ECS_TASKCOUNT_MONITOR_LAST_OUTPUT_FILE"
    echo "$tmux_output"
    exit 1
fi

task_count=$(aws ecs list-tasks --profile "$AWS_PROFILE_PULSEOWL_MONITOR" --cluster "$AWS_CLUSTER_PULSEOWL_MONITOR" --desired-status RUNNING | jq '.taskArns | length')

# Check if task_count is a valid integer
if ! [[ "$task_count" =~ ^[0-9]+$ ]]; then
    tmux_output="#[fg=red]PO-ECS ERR"
    osascript -e 'display notification "Failed to get ECS task count." with title "PulseOwl ECS Monitor Error"'
    # Cache the error state to prevent rapid retries
    echo "$current_time" > "$ECS_TASKCOUNT_MONITOR_LAST_RUN_FILE"
    echo "$tmux_output" > "$ECS_TASKCOUNT_MONITOR_LAST_OUTPUT_FILE"
    echo "$tmux_output"
    exit 1
fi

# Decide alert state and messages
if [ "$task_count" -ge 7 ]; then
    alert_state="ALERT"
    alert_msg=":red_circle: *ALERT!* ECS running task count is *$task_count* (>6) in PulseOwl cluster."
    tmux_output="#[fg=red]ALERT! PO-ECS: $task_count > 6"
elif [ "$task_count" -ge 2 ]; then
    alert_state="OK"
    alert_msg=":white_check_mark: ECS running task count back to normal: $task_count."
    tmux_output="#[fg=green]PO-ECS($task_count) "
else
    alert_state="WARNING"
    alert_msg=":warning: *WARNING!* ECS running task count is low: $task_count (<2)."
    tmux_output="#[fg=yellow]WARNING! PO-ECS: $task_count < 2"
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

# --- Caching and Final Output ---
# Save the current time and output for the next cached read
echo "$current_time" > "$ECS_TASKCOUNT_MONITOR_LAST_RUN_FILE"
echo "$tmux_output" > "$ECS_TASKCOUNT_MONITOR_LAST_OUTPUT_FILE"

# Display the output for this run
echo "$tmux_output"
