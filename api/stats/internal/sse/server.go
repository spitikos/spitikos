package sse

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"pi/stats/internal/stats"
	"time"
)

func StatsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	rc := http.NewResponseController(w)
	t := time.NewTicker(time.Second)
	defer t.Stop()

	for {
		select {
		case <-r.Context().Done():
			log.Println("Client disconnected")
			return
		case <-t.C:
			stats := stats.GetStats(r.Context())

			encoded, err := json.Marshal(stats)
			if err != nil {
				log.Printf("Error marshalling JSON: %v", err)
				continue
			}

			_, err = fmt.Fprintf(w, "data: %s\n\n", encoded)
			if err != nil {
				log.Printf("Error writing to response: %v", err)
				return
			}

			err = rc.Flush()
			if err != nil {
				log.Printf("Error flushing response: %v", err)
				return
			}
		}
	}
}
