#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORT 12345
#define BUFFER_SIZE 1024
#define BOARD_SIZE 3

char board[BOARD_SIZE][BOARD_SIZE];
int currentPlayer = 0; // 0 for Player 1, 1 for Player 2
int clients[2]; // Store client sockets for broadcasting

void initializeBoard() {
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            board[i][j] = ' ';
        }
    }
}

void printBoard() {
    printf("Current board:\n");
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            printf("%c", board[i][j]);
            if (j < BOARD_SIZE - 1) printf("|");
        }
        printf("\n");
        if (i < BOARD_SIZE - 1) printf("-----\n");
    }
}

void broadcastBoard() {
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

    // Broadcast the current board to both clients
    for (int i = 0; i < 2; i++) {
        send(clients[i], boardMessage, strlen(boardMessage), 0);
    }
}

void broadcast(const char *message) {
    for (int i = 0; i < 2; i++) {
        if (clients[i] != -1) { // Only send to connected clients
            send(clients[i], message, strlen(message), 0);
        }
    }
}

int checkWin() {
    for (int i = 0; i < BOARD_SIZE; i++) {
        // Check rows
        if (board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0] != ' ')
            return 1; // Win
        // Check columns
        if (board[0][i] == board[1][i] && board[1][i] == board[2][i] && board[0][i] != ' ')
            return 1; // Win
    }
    // Check diagonals
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != ' ')
        return 1; // Win
    if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != ' ')
        return 1; // Win

    // Check for draw
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            if (board[i][j] == ' ') return 0; // Game not over
        }
    }
    return -1; // Draw
}

// int askForReplay(int playerSocket, int playerIndex) {
//     char buffer[BUFFER_SIZE]; // Adjust size as necessary
//     char response[BUFFER_SIZE];

//     // Ask for a replay
//     send(playerSocket, "Do you want to play again? (yes/no): ", 39, 0);
//     recv(playerSocket, buffer, sizeof(buffer) - 1, 0); // -1 to leave space for null terminator
//     buffer[sizeof(buffer) - 1] = '\0';  // Ensure null-termination

//     // Format response
//     snprintf(response, sizeof(response), "%.500s\n", buffer);
//     printf("%s", response);
//     if (strcmp(response, "yes"))
//     {
//         return 1;
//     }
//     else
//     {
//         return 0;
//     }
    
// }
int askForReplay(int playerSocket, int playerIndex) {
    char buffer[BUFFER_SIZE]; // Adjust size as necessary
    char response[BUFFER_SIZE];

    // Ask for a replay
    send(playerSocket, "Do you want to play again? (yes/no): ", 39, 0);
    recv(playerSocket, buffer, sizeof(buffer) - 1, 0); // -1 to leave space for null terminator
    buffer[sizeof(buffer) - 1] = '\0';  // Ensure null-termination

    // Format response and strip whitespace
    snprintf(response, sizeof(response), "%.500s\n", buffer);
    // printf("Response from Player %d: %s", playerIndex + 1, response);
    
    // Check for "yes" or "no"
    // Use strcmp to compare with trimmed response
    if (strncmp(response, "yes", 3) == 0) {
        return 1; // Player wants to replay
    } else {
        return 0; // Player does not want to replay
    }
}


int main() {
    int server_fd, new_socket;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);

    // Create socket
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }

    // Bind the socket
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt))) {
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("bind failed");
        exit(EXIT_FAILURE);
    }

    // Listen for connections
    if (listen(server_fd, 2) < 0) {
        perror("listen");
        exit(EXIT_FAILURE);
    }
    printf("Waiting for players to connect...\n");

    // Accept two players
    for (int i = 0; i < 2; i++) {
        new_socket = accept(server_fd, (struct sockaddr *)&address, (socklen_t*)&addrlen);
        if (new_socket < 0) {
            perror("accept");
            exit(EXIT_FAILURE);
        }
        clients[i] = new_socket;
        printf("Player %d connected\n", i + 1);

        // Send welcome message
        char welcomeMessage[BUFFER_SIZE];
        snprintf(welcomeMessage, sizeof(welcomeMessage), "Welcome Player %d! You are '%c'.\n", i + 1, (i == 0) ? 'X' : 'O');
        send(clients[i], welcomeMessage, strlen(welcomeMessage), 0);

        // If it's the first player, wait for the second player to join
        if (i == 0) {
            char waitMessage[] = "Waiting for Player 2 to join...\n";
            send(clients[i], waitMessage, strlen(waitMessage), 0);
        }
    }
    
    // Game loop
    while (1) {
        // Initialize the board for the new game
        initializeBoard();
        char startMessage[] = "Both players are connected! Starting the game...\n";
        broadcast(startMessage);
        
        while (1) {
            char turnMessage[BUFFER_SIZE];
            snprintf(turnMessage, sizeof(turnMessage), "Player %d's turn. Enter your move (row col): ", currentPlayer + 1);
            send(clients[currentPlayer], turnMessage, strlen(turnMessage), 0);

            char buffer[BUFFER_SIZE];
            memset(buffer, 0, sizeof(buffer));
            int bytesReceived = recv(clients[currentPlayer], buffer, sizeof(buffer), 0);

            // Handle disconnection
            if (bytesReceived <= 0) {
                printf("Player %d disconnected\n", currentPlayer + 1);
                close(clients[currentPlayer]);
                clients[currentPlayer] = -1; // Mark client as disconnected
                break; // Exit the game loop
            }

            int moveRow, moveCol;
            sscanf(buffer, "%d %d", &moveRow, &moveCol);

            // Validate move (adjusting for 0-based index)
            if (moveRow < 1 || moveRow > BOARD_SIZE || moveCol < 1 || moveCol > BOARD_SIZE || board[moveRow-1][moveCol-1] != ' ') {
                char invalidMoveMessage[] = "Invalid move. Please try again.\n";
                send(clients[currentPlayer], invalidMoveMessage, strlen(invalidMoveMessage), 0);
                continue; // Skip to the next iteration to get a valid move
            }

            // Update board
            board[moveRow-1][moveCol-1] = (currentPlayer == 0) ? 'X' : 'O';

            // Print current board
            // printBoard();
            
            // Check for win or draw
            int gameState = checkWin();
            if (gameState == 1) {
                // Send winning message
                char winMessage[BUFFER_SIZE];
                snprintf(winMessage, sizeof(winMessage), "Player %d wins!\n", currentPlayer + 1);
                broadcast(winMessage);
                break; // Exit game loop
            } else if (gameState == -1) {
                // Send draw message
                char drawMessage[] = "It's a draw!\n";
                broadcast(drawMessage);
                break; // Exit game loop
            }

            // Switch players
            currentPlayer = (currentPlayer + 1) % 2;
            broadcastBoard();
        }
        int response[2];
        // Ask both players if they want to replay
        for (int i = 0; i < 2; i++) {
            if (clients[i] != -1) { // Only ask connected clients
                response[i] = askForReplay(clients[i], i);
                // printf("%d", response[i]);
            }
        }
                // Handle replay responses
        if (response[0] && response[1]) {
            // Both players want to replay
            char restartMessage[] = "Both players want to replay. Restarting the game...\n";
            broadcast(restartMessage);
            continue; // Continue to the next game
        } else if (response[0]) {
            // Player 1 wants to replay but Player 2 does not
            char player1Message[] = "Player 1 wants to replay, but Player 2 does not. Ending game.\n";
            broadcast(player1Message);
            break; // Exit the main game loop
        } else if (response[1]) {
            // Player 2 wants to replay but Player 1 does not
            char player2Message[] = "Player 2 wants to replay, but Player 1 does not. Ending game.\n";
            broadcast(player2Message);
            break; // Exit the main game loop
        } else {
            // Neither player wants to replay
            char endMessage[] = "Both players do not want to replay. Ending game.\n";
            broadcast(endMessage);
            break; // Exit the main game loop
        }

        // Restart the game or handle disconnections
        if (clients[0] == -1 || clients[1] == -1) {
            break; // Exit main game loop if a player disconnected
        }
    }

    // Close all client sockets
    for (int i = 0; i < 2; i++) {
        if (clients[i] != -1) {
            close(clients[i]);
        }
    }

    close(server_fd);
    return 0;
}
