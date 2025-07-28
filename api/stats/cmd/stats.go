package main

import (
	"log"
	"net/http"
	"pi/stats/internal/sse"
)

func main() {
	http.HandleFunc("/", sse.StatsHandler)

	log.Println("Server starting on :8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
