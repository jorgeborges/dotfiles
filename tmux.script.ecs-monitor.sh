#!/bin/bash

# --- Configuration ---
# The script will only perform a full check once per this interval (in seconds)
EXECUTION_INTERVAL_SECONDS=300
TASK_COUNT_HIGH_ALERT_THRESHOLD=8
TASK_COUNT_LOW_ALERT_THRESHOLD=1

# Determine the script's directory to build a path to the project's tmp/ folder.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_TMP_DIR="$SCRIPT_DIR/tmp"

# Create the tmp directory if it doesn't exist.
mkdir -p "$PROJECT_TMP_DIR"

# Define state and cache file paths within the project's tmp directory.
STATE_FILE="$PROJECT_TMP_DIR/pulseowl_ecs_taskcount.state"
LAST_RUN_FILE="$PROJECT_TMP_DIR/pulseowl_ecs_monitor.lastrun"
LAST_OUTPUT_FILE="$PROJECT_TMP_DIR/pulseowl_ecs_monitor.lastoutput"

# --- Rate-Limiting Logic ---
current_time=$(date +%s)
last_run_time=0
if [ -f "$LAST_RUN_FILE" ]; then
    last_run_time=$(cat "$LAST_RUN_FILE")
fi

time_since_last_run=$((current_time - last_run_time))

# If the interval has not passed and we have a cached output, show it and exit.
if [ "$time_since_last_run" -lt "$EXECUTION_INTERVAL_SECONDS" ] && [ -f "$LAST_OUTPUT_FILE" ]; then
    cat "$LAST_OUTPUT_FILE"
    exit 0
fi

# --- Main Monitoring Logic ---

# Ensure webhook URL is set.
if [ -z "$PULSEOWL_ALERT_APP_WEBHOOK_URL" ]; then
    tmux_output="#[fg=red]PO-ECS ERR: ENV not set"
    echo "$current_time" > "$LAST_RUN_FILE"
    echo "$tmux_output" > "$LAST_OUTPUT_FILE"
    echo "$tmux_output"
    exit 1
fi

task_count=$(aws ecs list-tasks --profile "$AWS_PROFILE_PULSEOWL_MONITOR" --cluster "$AWS_CLUSTER_PULSEOWL_MONITOR" --desired-status RUNNING | jq '.taskArns | length')

# Check if task_count is a valid integer
if ! [[ "$task_count" =~ ^[0-9]+$ ]]; then
    tmux_output="#[fg=red]PO-ECS ERR"
    osascript -e 'display notification "Failed to get ECS task count." with title "PulseOwl ECS Monitor Error"'
    # Cache the error state to prevent rapid retries
    echo "$current_time" > "$LAST_RUN_FILE"
    echo "$tmux_output" > "$LAST_OUTPUT_FILE"
    echo "$tmux_output"
    exit 1
fi

# Decide alert state and messages
if [ "$task_count" -ge "$TASK_COUNT_HIGH_ALERT_THRESHOLD" ]; then
    alert_state="ALERT"
    alert_msg=":red_circle: *ALERT!* ECS running task count is *$task_count* (>=$TASK_COUNT_HIGH_ALERT_THRESHOLD) in PulseOwl cluster."
    tmux_output="#[fg=red]ALERT! PO-ECS: $task_count >= $TASK_COUNT_HIGH_ALERT_THRESHOLD"
elif [ "$task_count" -ge "$TASK_COUNT_LOW_ALERT_THRESHOLD" ]; then
    alert_state="OK"
    alert_msg=":white_check_mark: ECS running task count back to normal: $task_count (>=$TASK_COUNT_LOW_ALERT_THRESHOLD)."
    tmux_output="#[fg=green]PO-ECS($task_count) "
else
    alert_state="WARNING"
    alert_msg=":warning: *WARNING!* ECS running task count is low: $task_count (< $TASK_COUNT_LOW_ALERT_THRESHOLD)."
    tmux_output="#[fg=yellow]WARNING! PO-ECS: $task_count < $TASK_COUNT_LOW_ALERT_THRESHOLD"
fi

# --- State Management and Notification ---

# On the very first run, the state file won't exist.
# In this case, we create it and exit to prevent a false positive alert.
if [ ! -f "$STATE_FILE" ]; then
    echo "$alert_state" > "$STATE_FILE"
    echo "$current_time" > "$LAST_RUN_FILE"
    echo "$tmux_output" > "$LAST_OUTPUT_FILE"
    echo "$tmux_output"
    exit 0
fi

# Read last alert state
last_state=$(cat "$STATE_FILE")

# Send to Slack *only if state has changed*
if [ "$alert_state" != "$last_state" ]; then
    curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$alert_msg\"}" "$PULSEOWL_ALERT_APP_WEBHOOK_URL" > /dev/null
fi

# Save current state for next run
echo "$alert_state" > "$STATE_FILE"

# --- Caching and Final Output ---
# Save the current time and output for the next cached read
echo "$current_time" > "$LAST_RUN_FILE"
echo "$tmux_output" > "$LAST_OUTPUT_FILE"

# Display the output for this run
echo "$tmux_output"
