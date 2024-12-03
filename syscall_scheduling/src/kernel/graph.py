import matplotlib.pyplot as plt

# Initialize a dictionary to store data for each line
data = {}

# Read and process the log file
with open('logs69', 'r') as file:
    for line in file:
        values = line.split()
        if len(values) >= 3:
            x = float(values[0])
            line_id = int(values[1])  # Using the second number as a line identifier
            if line_id == 2:
                continue
            y = float(values[2])

            # Store the data points in the dictionary based on line_id
            if line_id not in data:
                data[line_id] = {'x': [], 'y': []}

            data[line_id]['x'].append(x)
            data[line_id]['y'].append(y)

# Plot the data
for line_id, points in data.items():
    plt.plot(points['x'], points['y'], label=f'Line {line_id}')

# Add labels and title
plt.xlabel('Ticks')
plt.ylabel('Queue-level')
plt.title('Plot of Data from logs69')
plt.legend()
# plt.gca().invert_yaxis()

# Show the plot
plt.show()