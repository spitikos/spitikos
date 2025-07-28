package stats

import (
	"context"

	"github.com/shirou/gopsutil/v3/host"
)

type HostStat struct {
	BootTime     uint64 `json:"bootTime"`
	Uptime       uint64 `json:"uptime"`
	Processes    uint64 `json:"processes"`
	OS           string `json:"os"`
	Platform     string `json:"platform"`
	Architecture string `json:"architecture"`
}

func getHostStat(ctx context.Context) (HostStat, error) {
	host.EnableBootTimeCache(true)
	infoStat, err := host.InfoWithContext(ctx)
	if err != nil {
		return HostStat{}, err
	}

	return HostStat{
		BootTime:     infoStat.BootTime,
		Uptime:       infoStat.Uptime,
		Processes:    infoStat.Procs,
		OS:           infoStat.OS,
		Platform:     infoStat.Platform,
		Architecture: infoStat.KernelArch,
	}, nil
}
