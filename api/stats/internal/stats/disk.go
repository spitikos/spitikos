package stats

import (
	"context"

	"github.com/shirou/gopsutil/v3/disk"
)

type DiskStat struct {
	Total       uint64  `json:"total"`
	Free        uint64  `json:"free"`
	Used        uint64  `json:"used"`
	UsedPercent float64 `json:"usedPercent"`
}

func getDiskStat(ctx context.Context) (DiskStat, error) {
	stat, err := disk.UsageWithContext(ctx, "/")
	if err != nil {
		return DiskStat{}, err
	}

	return DiskStat{
		Total:       stat.Total,
		Free:        stat.Free,
		Used:        stat.Used,
		UsedPercent: stat.UsedPercent,
	}, nil
}