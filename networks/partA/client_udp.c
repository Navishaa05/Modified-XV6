#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORT 12345
#define BUFFER_SIZE 1024

int main() {
    int sock;
    struct sockaddr_in server_addr;
    socklen_t addr_len = sizeof(server_addr);
    char buffer[BUFFER_SIZE];

    if ((sock = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("Socket creation error");
        return -1;
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Send a message to the server to register
    char *register_msg = "Player ready";
    sendto(sock, register_msg, strlen(register_msg), 0, (struct sockaddr*)&server_addr, sizeof(server_addr));

    while (1) {
        // Receive messages from the server
        int n = recvfrom(sock, buffer, BUFFER_SIZE, 0, (struct sockaddr*)&server_addr, &addr_len);
        buffer[n] = '\0'; // Null-terminate the received message

        // Check if the server is closing the connection
        if (strcmp(buffer, "Server is closing the connection.\n") == 0) {
            printf("%s", buffer);
            break; // Exit the loop and close the client
        }

        printf("%s", buffer); // Print the server message

        // If it's a prompt for a move, read the player's input
        if (strstr(buffer, "enter your move") != NULL) {
            int row, col;
            printf("Enter your move (row and column): ");
            scanf("%d %d", &row, &col);

            // Send the move to the server
            char move_msg[50];
            snprintf(move_msg, sizeof(move_msg), "%d %d", row, col);
            sendto(sock, move_msg, strlen(move_msg), 0, (struct sockaddr*)&server_addr, sizeof(server_addr));
        } else if (strstr(buffer, "Game over!") != NULL) {
            // Prompt for replay
            char replay[4];
            printf("Do you want to play again? (yes/no): ");
            scanf("%3s", replay);

            // Send the response back to the server
            sendto(sock, replay, strlen(replay), 0, (struct sockaddr*)&server_addr, sizeof(server_addr));
        }
    }

    close(sock);
    return 0;
}
