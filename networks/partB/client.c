#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORT 8080
#define CHUNK_SIZE 5

typedef struct {
    int seq_num;         // Sequence number of the chunk
    int total_chunks;    // Total number of chunks being sent
    char data[CHUNK_SIZE]; // Data chunk
} Chunk;

int main() {
    int sockfd;
    struct sockaddr_in server_addr;
    Chunk chunk;
    char message[4096]; // Buffer for the message to send

    // Create UDP socket
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1"); // Change this if needed

    // Prompt for the message
    printf("Enter the message to send: ");
    fgets(message, sizeof(message), stdin);
    message[strcspn(message, "\n")] = 0; // Remove newline

    // Determine total chunks and send chunks
    int total_length = strlen(message);
    chunk.total_chunks = (total_length + CHUNK_SIZE - 1) / CHUNK_SIZE; // Calculate total chunks
    printf("Total chunks: %d\n", chunk.total_chunks);

    for (int i = 0; i < chunk.total_chunks; i++) {
        chunk.seq_num = i; // Set sequence number
        strncpy(chunk.data, message + i * CHUNK_SIZE, CHUNK_SIZE); // Copy chunk data
        sendto(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
        printf("Sent chunk %d/%d: %s\n", chunk.seq_num + 1, chunk.total_chunks, chunk.data);
        
        // Wait for ACK (not implemented here, but you can add a recv call)
    }

    close(sockfd);
    return 0;
}
