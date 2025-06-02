#!/bin/bash

# Load env
set -a
source .env
set +a

LAST_MESSAGE_ID_FILE=".last_message_id"
LOG_FILE="log.txt"
DAILY_SUMMARY_FILE="daily_summary.txt"
WEEKLY_SUMMARY_FILE="weekly_summary.txt"
STATS_FILE="signal_stats.json"

if [ ! -f "$LAST_MESSAGE_ID_FILE" ]; then echo "0" > "$LAST_MESSAGE_ID_FILE"; fi
if [ ! -f "$STATS_FILE" ]; then echo "{}" > "$STATS_FILE"; fi

send_telegram() {
    local text="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_PERSONAL_CHAT_ID" \
        --data-urlencode "text=$text"
}

send_to_google_sheets() {
    local date="$1"
    local summary="$2"
    curl -s -X POST "$GOOGLE_SHEETS_API_URL" \
        -H "Content-Type: application/json" \
        -d "[{\"date\":\"$date\", \"summary\":\"$summary\"}]"
}

daily_summary() {
    summary=$(python3 summary_helper.py --daily "$DAILY_SUMMARY_FILE")
    clean_summary=$(echo "$summary" | tr '\n' '; ')
    date=$(date '+%Y-%m-%d')

    send_to_google_sheets "$date" "$clean_summary"
    send_telegram "$summary"
    send_telegram "✅ Summary untuk $date sudah dikirim ke Google Sheets dan Telegram."

    echo "" > "$DAILY_SUMMARY_FILE"
}

weekly_summary() {
    summary=$(python3 summary_helper.py --weekly "$WEEKLY_SUMMARY_FILE" "$STATS_FILE")
    send_telegram "$summary"

    echo "" > "$WEEKLY_SUMMARY_FILE"
    echo "{}" > "$STATS_FILE"
}

while true; do
    echo "🔍 Checking Telegram channel..."

    output=$(python3 fetch.py)
    message_id=$(echo "$output" | cut -d'|' -f1)
    message_text=$(echo "$output" | cut -d'|' -f2-)

    last_id=$(cat "$LAST_MESSAGE_ID_FILE")

    if [ "$message_id" != "" ] && [ "$message_id" != "$last_id" ]; then
        echo "✅ New message (ID: $message_id)"
        echo "$message_text" >> "$DAILY_SUMMARY_FILE"
        echo "$message_text" >> "$WEEKLY_SUMMARY_FILE"
        python3 summary_helper.py --update-stats "$STATS_FILE" "$message_text"

        echo "$(date '+%Y-%m-%d %H:%M:%S') | $message_text" >> "$LOG_FILE"
        send_telegram "📢 New Signal:\n$message_text"
        echo "$message_id" > "$LAST_MESSAGE_ID_FILE"
    fi

    # Daily summary at 23:59
    if [[ $(date '+%H:%M') == "23:59" ]]; then daily_summary; fi

    # Weekly summary on Sunday 23:59
    if [[ $(date '+%u') == 7 && $(date '+%H:%M') == "23:59" ]]; then weekly_summary; fi

    echo "⏳ Sleeping for 1 second..."
    sleep 1
done
