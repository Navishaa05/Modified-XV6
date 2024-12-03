import matplotlib.pyplot as plt
import numpy as np

def parse_log(filename):
    data = []
    with open(filename, 'r') as f:
        for line in f:
            pid, queue, time = map(int, line.strip().split(','))
            if 4 <= pid <= 13:  # Only consider processes 4-13
                data.append((pid, queue, time))
    return data

def apply_priority_boost(data, max_ticks=200):
    boosted_data = []
    for pid in range(4, 14):  # Processes 4-13
        process_data = sorted([(t, q) for p, q, t in data if p == pid])
        last_time = -1
        last_queue = 0
        
        for time in range(max_ticks + 1):
            if time % 48 == 0 and time > 0:
                boosted_data.append((pid, 0, time - 1))  # Point just before boost
                boosted_data.append((pid, 0, time))  # Boost point
                last_queue = 0
            elif process_data and time == process_data[0][0]:
                _, queue = process_data.pop(0)
                boosted_data.append((pid, queue, time))
                last_queue = queue
            elif time > last_time:
                boosted_data.append((pid, last_queue, time))
            
            last_time = time
    
    return boosted_data

def plot_timeline(data):
    fig, ax = plt.subplots(figsize=(15, 10))
    colors = plt.cm.tab10(np.linspace(0, 1, 10))  # 10 distinct colors for processes 4-13
    pid_to_color = dict(zip(range(4, 14), colors))

    for pid in range(4, 14):
        process_data = sorted([(t, q) for p, q, t in data if p == pid])
        if process_data:  # Only plot if there's data for this process
            times, queues = zip(*process_data)
            ax.step(times, queues, where='post', color=pid_to_color[pid], label=f'P{pid}', linewidth=2)

    ax.set_yticks(range(4))
    ax.set_yticklabels(['Q0', 'Q1', 'Q2', 'Q3'])
    ax.set_xlabel('Number of ticks')
    ax.set_ylabel('Queue Number')
    ax.set_title('Process Queue Timeline (P4-P13) with Priority Boost every 48 ticks')

    # Add priority boost indicators
    boost_times = range(0, 201, 48)
    for boost_time in boost_times:
        ax.axvline(x=boost_time, color='gray', linestyle='--', alpha=0.5)

    ax.text(0.02, 0.98, 'Priority boost: every 48 ticks', transform=ax.transAxes,
            verticalalignment='top', fontsize=10)

    # Improve legend placement and visibility
    ax.legend(loc='center left', bbox_to_anchor=(1, 0.5), fontsize=10)

    ax.set_ylim(-0.5, 3.5)
    ax.set_xlim(0, 200)
    ax.grid(True, which='both', linestyle=':', alpha=0.6)

    plt.tight_layout()
    plt.show()

# Usage
data = parse_log('xv6_scheduler_log.txt')
boosted_data = apply_priority_boost(data)
plot_timeline(boosted_data)