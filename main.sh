#!/bin/bash

# Load environment variables
set -a
source .env
set +a

LAST_MESSAGE_ID_FILE=".last_message_id"
LOG_FILE="log.txt"
SUMMARY_FILE="daily_summary.txt"

if [ ! -f "$LAST_MESSAGE_ID_FILE" ]; then
    echo "0" > "$LAST_MESSAGE_ID_FILE"
fi

function send_telegram() {
    local text="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_PERSONAL_CHAT_ID" \
        --data-urlencode "text=$text"
}

function send_to_google_sheets() {
    local date="$1"
    local summary="$2"
    curl -s -X POST "$GOOGLE_SHEETS_API_URL" \
        -H "Content-Type: application/json" \
        -d "{\"date\":\"$date\", \"summary\":\"$summary\"}"
}

function check_and_send_summary() {
    local hour=$(date '+%H')
    local minute=$(date '+%M')
    if [ "$hour" == "23" ] && [ "$minute" == "59" ]; then
        if [ -f "$SUMMARY_FILE" ]; then
            summary=$(cat "$SUMMARY_FILE")
            send_to_google_sheets "$(date '+%Y-%m-%d')" "$summary"
            send_telegram "📊 Daily Summary:\n$summary"
            echo "" > "$SUMMARY_FILE"
        fi
    fi
}

while true; do
    echo "🔍 Checking Telegram channel..."

    output=$(python3 fetch_telegram.py)
    message_id=$(echo "$output" | cut -d'|' -f1)
    message_text=$(echo "$output" | cut -d'|' -f2-)

    last_id=$(cat "$LAST_MESSAGE_ID_FILE")

    if [ "$message_id" != "" ] && [ "$message_id" != "$last_id" ]; then
        echo "✅ New message (ID: $message_id), sending to Telegram bot..."
        formatted="📢 New Signal:\n$message_text"

        # Send to Telegram
        send_telegram "$formatted"

        # Log to file
        echo "$(date '+%Y-%m-%d %H:%M:%S') | $message_text" >> "$LOG_FILE"
        echo "$message_text" >> "$SUMMARY_FILE"

        # Update last ID
        echo "$message_id" > "$LAST_MESSAGE_ID_FILE"
    else
        echo "⚠ No new matching message."
    fi

    # Check for daily summary
    check_and_send_summary

    echo "⏳ Sleeping for 2 minutes..."
    sleep 120
done
