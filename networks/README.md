# Networking

# Part A

# Tic-Tac-Toe Network Game

## Assumptions
1. The code is compiled and executed in a Linux environment.
2. The server is run before the clients connect.
3. Both TCP and UDP versions use port 12345 by default.
4. The game is played between two players.
5. Players take turns making moves.
6. The game board is 3x3.
7. Input for moves is 1-indexed (1-3 for both row and column).
8. Invalid moves are rejected, and the player is prompted to try again.
9. The game continues until there's a win or a draw.
10. After each game, players are asked if they want to play again.
11. The server closes when both players decide not to play again or when one player disconnects.

## Files and Functions

### 1. `server.c` (TCP Version)
- **Purpose**: Implements the TCP server for the Tic-Tac-Toe game.
- **Main Functions**:
  - `void initializeBoard()`: Initializes the game board.
  - `void printBoard()`: Prints the current state of the board.
  - `void broadcastBoard()`: Sends the current board state to both clients.
  - `int checkWin()`: Checks if the current board state results in a win.
  - `int askForReplay(int playerSocket, int playerIndex)`: Asks a player if they want to play again.

### 2. `client.c` (TCP Version)
- **Purpose**: Implements the TCP client for the Tic-Tac-Toe game.
- **Main Function**:
  - `int main()`: Handles connection to the server, receives game updates, and sends player moves.

### 3. `server_udp.c` (UDP Version)
- **Purpose**: Implements the UDP server for the Tic-Tac-Toe game.
- **Main Functions**:
  - `void initializeBoard()`: Initializes the game board.
  - `void broadcast(int server_fd, const char *message)`: Sends a message to all connected clients.
  - `void broadcastBoard(int server_fd)`: Sends the current board state to all clients.
  - `int checkWin()`: Checks if the current board state results in a win.

### 4. `client_udp.c` (UDP Version)
- **Purpose**: Implements the UDP client for the Tic-Tac-Toe game.
- **Main Function**:
  - `int main()`: Handles connection to the server, receives game updates, and sends player moves.

## Usage
1. Compile the code using GCC:
   ```bash
   gcc -o server server.c
   gcc -o client client.c
   gcc -o server_udp server_udp.c
   gcc -o client_udp client_udp.c
   ```

2. Run the server (choose either TCP or UDP version):
   ```bash
   ./server
   ```
   or
   ```bash
   ./server_udp
   ```

3. Run two instances of the client in separate terminals (match the version with the server):
   ```bash
   ./client
   ```
   or
   ```bash
   ./client_udp
   ```

4. Follow the prompts to play the game.

## Notes
- The server uses localhost (127.0.0.1) and port 12345 by default.
- Ensure the server is running before connecting clients.
- The UDP version requires an initial message from clients to register with the server.
- Input for moves should be two space-separated integers (row and column), e.g., "2 3".
- To end the game, both players should choose not to play again when prompted.

# Part B

# UDP-based File Transfer System

## Assumptions
1. The code is compiled and executed in a Linux environment.
2. The server is run before the client connects.
3. Both client and server use port 8080 by default.
4. The system uses UDP for communication.
5. Messages are split into chunks of 5 bytes each.
6. The client sends the entire message in chunks, and the server reassembles it.
7. The server sends ACKs for each received chunk (currently implemented but commented out for testing purposes).
8. The maximum message size is 4096 bytes.
9. The client and server are assumed to run on the same machine (localhost) by default.

## Files and Functions

### 1. `client.c`
- **Purpose**: Implements the client side of the UDP-based file transfer system.
- **Main Functions**:
  - `int main()`: Handles connection to the server, chunks the message, and sends it to the server.

### 2. `server.c`
- **Purpose**: Implements the server side of the UDP-based file transfer system.
- **Main Functions**:
  - `int main()`: Sets up the UDP socket, receives chunks from the client, reassembles the message, and optionally sends ACKs.

## Data Structure
Both client and server use the following structure for data chunks:
```c
typedef struct {
    int seq_num;         // Sequence number of the chunk
    int total_chunks;    // Total number of chunks being sent
    char data[CHUNK_SIZE]; // Data chunk
} Chunk;
```

## Usage
1. Compile the code using GCC:
   ```bash
   gcc -o server server.c
   gcc -o client client.c
   ```

2. Run the server:
   ```bash
   ./server
   ```

3. In a separate terminal, run the client:
   ```bash
   ./client
   ```

4. When prompted by the client, enter the message you want to send.

## Notes
- The server uses INADDR_ANY and port 8080 by default.
- The client uses localhost (127.0.0.1) and port 8080 by default.
- Ensure the server is running before starting the client.
- The current implementation does not handle packet loss or out-of-order delivery. It assumes all packets arrive in order.
- ACK functionality is implemented but commented out in the server for testing purposes. Uncomment the relevant code in `server.c` to enable ACKs.
- Every third ACK is skipped in the current implementation to simulate packet loss (this feature is commented out).

## Potential Improvements
1. Implement a sliding window protocol for better efficiency.
2. Add error checking and handling for lost or corrupted packets.
3. Implement timeout and retransmission on the client side.
4. Add support for larger file transfers.
5. Implement flow control to prevent overwhelming the receiver.
