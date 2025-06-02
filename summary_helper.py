import sys
import json
import collections

def parse_file(file_path):
    with open(file_path, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
    return lines

def count_keywords(lines, keywords=['BTC', 'ETH', 'LONG', 'SHORT']):
    counter = collections.Counter()
    for line in lines:
        for kw in keywords:
            if kw in line.upper():
                counter[kw] += 1
    return counter

def update_stats(stats_file, message):
    with open(stats_file, 'r') as f:
        stats = json.load(f)
    outcome = 'pending'
    if 'WIN' in message.upper():
        outcome = 'win'
    elif 'LOSS' in message.upper():
        outcome = 'loss'
    stats.setdefault(outcome, 0)
    stats[outcome] += 1
    with open(stats_file, 'w') as f:
        json.dump(stats, f)

if '--daily' in sys.argv:
    file = sys.argv[sys.argv.index('--daily') + 1]
    lines = parse_file(file)
    total = len(lines)
    keywords = count_keywords(lines)
    summary = f"📊 Daily Summary ({total} signals)\n"
    summary += "Top keywords: " + ', '.join([f"{k}({v})" for k,v in keywords.items()]) + "\n\nSignals:\n"
    summary += '\n'.join([f"• {line}" for line in lines])
    print(summary)

elif '--weekly' in sys.argv:
    file = sys.argv[sys.argv.index('--weekly') + 1]
    stats_file = sys.argv[sys.argv.index('--weekly') + 2]
    lines = parse_file(file)
    total = len(lines)
    keywords = count_keywords(lines)
    with open(stats_file, 'r') as f:
        stats = json.load(f)
    summary = f"📈 Weekly Summary\nTotal signals: {total}\n"
    summary += "Top keywords: " + ', '.join([f"{k}({v})" for k,v in keywords.items()]) + "\n"
    summary += f"Performance:\n✅ Wins: {stats.get('win',0)}\n❌ Losses: {stats.get('loss',0)}\n🤔 Pending: {stats.get('pending',0)}"
    print(summary)

elif '--update-stats' in sys.argv:
    stats_file = sys.argv[sys.argv.index('--update-stats') + 1]
    message = sys.argv[sys.argv.index('--update-stats') + 2]
    update_stats(stats_file, message)
