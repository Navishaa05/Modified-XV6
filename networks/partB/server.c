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
    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_len = sizeof(client_addr);
    Chunk chunk;
    
    // Create UDP socket
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    // Bind the socket to the server address
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(sockfd, (const struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("Bind failed");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    // Receive all chunks
    printf("Server is waiting for data...\n");
    char received_data[4096];  // Buffer to reassemble the full message
    memset(received_data, 0, sizeof(received_data));  // Initialize the buffer

    int ack_counter = 0;  // Counter to keep track of ACKs sent

    while (1) {
        // Receive a chunk
        recvfrom(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&client_addr, &addr_len);
        printf("Received chunk %d/%d: %s\n", chunk.seq_num + 1, chunk.total_chunks, chunk.data);

        // Reassemble the message by placing the chunk data at the correct position
        strncpy(received_data + chunk.seq_num * CHUNK_SIZE, chunk.data, CHUNK_SIZE);

        // Send an ACK back for the received chunk
        ack_counter++;
        
        // Skip every third ACK for testing retransmission
        // if (ack_counter % 3 == 0) {
        //     printf("Skipping ACK for chunk %d\n", chunk.seq_num);
        //     continue;  // Skip sending ACK
        // } else {
            char ack_msg[32];  // Buffer for ACK message
            snprintf(ack_msg, sizeof(ack_msg), "ACK %d", chunk.seq_num);
            sendto(sockfd, ack_msg, strlen(ack_msg), 0, (struct sockaddr *)&client_addr, addr_len);
            printf("Sent ACK for chunk %d\n", chunk.seq_num + 1);
        // }

        // If we have received all chunks, display the full message
        if (chunk.seq_num == chunk.total_chunks - 1) {
            printf("Full message received: %s\n", received_data);
            break;  // Exit loop when all chunks are received
        }
    }

    close(sockfd);
    return 0;
}
