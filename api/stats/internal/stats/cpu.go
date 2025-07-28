package stats

import (
	"context"

	"github.com/shirou/gopsutil/v3/cpu"
)

type CPUStat []float64

func getCPUStat(ctx context.Context) (CPUStat, error) {
	stat, err := cpu.PercentWithContext(ctx, 0, true)
	if err != nil {
		return nil, err
	}

	return CPUStat(stat), nil
}
