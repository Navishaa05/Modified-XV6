#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORT 12345
#define BUFFER_SIZE 1024
#define BOARD_SIZE 3

char board[BOARD_SIZE][BOARD_SIZE];
struct sockaddr_in clients[2]; // Store client addresses for broadcasting
int client_count = 0;

void initializeBoard() {
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            board[i][j] = ' ';
        }
    }
}

void broadcast(int server_fd, const char *message) {
    for (int i = 0; i < client_count; i++) {
        sendto(server_fd, message, strlen(message), 0, (struct sockaddr*)&clients[i], sizeof(clients[i]));
    }
}

void broadcastBoard(int server_fd) {
    char boardMessage[BUFFER_SIZE];
    snprintf(boardMessage, sizeof(boardMessage), "Current board:\n");
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            snprintf(boardMessage + strlen(boardMessage), sizeof(boardMessage) - strlen(boardMessage), "%c", board[i][j]);
            if (j < BOARD_SIZE - 1) strncat(boardMessage, "|", sizeof(boardMessage) - strlen(boardMessage) - 1);
        }
        strncat(boardMessage, "\n", sizeof(boardMessage) - strlen(boardMessage) - 1);
        if (i < BOARD_SIZE - 1) strncat(boardMessage, "-----\n", sizeof(boardMessage) - strlen(boardMessage) - 1);
    }

    broadcast(server_fd, boardMessage);
}

int checkWin() {
    // Check rows and columns
    for (int i = 0; i < BOARD_SIZE; i++) {
        if ((board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0] != ' ') ||
            (board[0][i] == board[1][i] && board[1][i] == board[2][i] && board[0][i] != ' ')) {
            return 1; // Win detected
        }
    }
    // Check diagonals
    if ((board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != ' ') ||
        (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != ' ')) {
        return 1; // Win detected
    }
    return 0; // No win
}

int main() {
    int server_fd;
    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_len = sizeof(client_addr);
    char buffer[BUFFER_SIZE];

    if ((server_fd = socket(AF_INET, SOCK_DGRAM, 0)) == 0) {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("bind failed");
        exit(EXIT_FAILURE);
    }
    printf("Waiting for players to connect...\n");

    // Waiting for two clients to send initial message to register them
    for (int i = 0; i < 2; i++) {
        recvfrom(server_fd, buffer, sizeof(buffer), 0, (struct sockaddr*)&clients[client_count], &addr_len);
        printf("Player %d connected\n", i + 1);
        client_count++;
    }

    // Game loop
    while (1) {
        // Initialize the board for a new game
        initializeBoard();
        broadcast(server_fd, "New game started. Player 1's turn.\n");

        int turn = 0;
        int move_count = 0;
        int game_over = 0;

        while (!game_over) {
            // Broadcast the current board
            broadcastBoard(server_fd);

            // Prepare to receive a move from the current player
            int current_player = turn % 2;
            snprintf(buffer, sizeof(buffer), "Player %d, enter your move (row and column, 1-based): ", current_player + 1);
            sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr*)&clients[current_player], addr_len);

            // Receive the move from the current player
            int n = recvfrom(server_fd, buffer, BUFFER_SIZE, 0, (struct sockaddr*)&client_addr, &addr_len);
            buffer[n] = '\0';

            // Parse the move (1-based to 0-based)
            int row, col;
            sscanf(buffer, "%d %d", &row, &col);

            // Convert to 0-based indexing
            row -= 1; // Convert from 1-based to 0-based
            col -= 1; // Convert from 1-based to 0-based

            // Validate move
            if (row < 0 || row >= BOARD_SIZE || col < 0 || col >= BOARD_SIZE || board[row][col] != ' ') {
                char *error_msg = "Invalid move. Try again.\n";
                sendto(server_fd, error_msg, strlen(error_msg), 0, (struct sockaddr*)&clients[current_player], addr_len);
                continue;
            }

            // Update the board
            board[row][col] = (turn % 2 == 0) ? 'X' : 'O';
            move_count++;

            // Check for a win or draw
            if (checkWin()) {
                snprintf(buffer, sizeof(buffer), "Player %d wins!\n", current_player + 1);
                broadcast(server_fd, buffer);
                game_over = 1;
            } else if (move_count == BOARD_SIZE * BOARD_SIZE) {
                broadcast(server_fd, "It's a draw!\n");
                game_over = 1;
            }

            turn++;
        }

        // Ask players if they want to play again
        char *replay_msg = "Game over! Do you want to play again? (yes/no)\n";
        broadcast(server_fd, replay_msg);

        // Wait for both players to respond
        int responses[2] = {0, 0}; // 0: no, 1: yes
        for (int i = 0; i < 2; i++) {
            int n = recvfrom(server_fd, buffer, BUFFER_SIZE, 0, (struct sockaddr*)&client_addr, &addr_len);
            buffer[n] = '\0';  // Null-terminate the received message

            if (strcmp(buffer, "yes") == 0) {
                responses[i] = 1; // Player wants to play again
            } else {
                responses[i] = 0; // Player does not want to play again
            }
        }

        if (responses[0] == 1 && responses[1] == 1) {
            // Both players said yes
            continue; // Restart the game
        } else if (responses[0] == 0 && responses[1] == 0) {
            // Both players said no
            broadcast(server_fd, "Thanks for playing!\n");
            break; // Exit the server loop
        } else {
            // One player wants to continue, the other does not
            int continuing_player = responses[0] == 1 ? 1 : 0;
            snprintf(buffer, sizeof(buffer), "Player %d did not wish to play again. Connection closing.\n", continuing_player + 1);
            broadcast(server_fd, buffer);
            break; // Exit the server loop
        }
    }

    // Notify clients before closing the server
    for (int i = 0; i < client_count; i++) {
        sendto(server_fd, "Server is closing the connection.\n", 36, 0, (struct sockaddr*)&clients[i], sizeof(clients[i]));
    }

    close(server_fd);
    return 0;
}
