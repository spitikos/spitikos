package stats

import (
	"context"

	"github.com/shirou/gopsutil/v3/mem"
)

type MemoryStat struct {
	Total       uint64  `json:"total"`
	Available   uint64  `json:"available"`
	Used        uint64  `json:"used"`
	UsedPercent float64 `json:"used_percent"`
}

func getMemoryStat(ctx context.Context) (MemoryStat, error) {
	stat, err := mem.VirtualMemoryWithContext(ctx)
	if err != nil {
		return MemoryStat{}, err
	}

	return MemoryStat{
		Total:       stat.Total,
		Available:   stat.Available,
		Used:        stat.Used,
		UsedPercent: stat.UsedPercent,
	}, nil
}
