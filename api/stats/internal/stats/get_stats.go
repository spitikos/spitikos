package stats

import (
	"context"
	"log"
	"sync"
	"time"
)

type statFetcher struct {
	name  string
	fetch func(ctx context.Context) (any, error)
}

func GetStats(requestCtx context.Context) *map[string]any {
	ctx, cancel := context.WithTimeout(requestCtx, time.Second)
	defer cancel()

	fetchers := []statFetcher{
		{name: "cpu", fetch: func(ctx context.Context) (any, error) { return getCPUStat(ctx) }},
		{name: "disk", fetch: func(ctx context.Context) (any, error) { return getDiskStat(ctx) }},
		{name: "host", fetch: func(ctx context.Context) (any, error) { return getHostStat(ctx) }},
		{name: "memory", fetch: func(ctx context.Context) (any, error) { return getMemoryStat(ctx) }},
		{name: "temperature", fetch: func(ctx context.Context) (any, error) { return getTemperatureStat(ctx) }},
	}

	stats := make(map[string]any)
	var wg sync.WaitGroup
	var mu sync.Mutex

	wg.Add(len(fetchers))

	for _, fetcher := range fetchers {
		go func(f statFetcher) {
			defer wg.Done()

			result, err := f.fetch(ctx)
			if err != nil {
				log.Printf("Error getting %s stat: %v", f.name, err)
				return
			}

			mu.Lock()
			defer mu.Unlock()
			stats[f.name] = result
		}(fetcher)
	}

	wg.Wait()
	return &stats
}
