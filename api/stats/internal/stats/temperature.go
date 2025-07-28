package stats

import (
	"context"

	"github.com/shirou/gopsutil/v3/host"
)

type TemperatureStat struct {
	CPU  float64 `json:"cpuTemperature"`
	NVME float64 `json:"nvmeTemperature"`
}

func getTemperatureStat(ctx context.Context) (TemperatureStat, error) {
	stat, err := host.SensorsTemperaturesWithContext(ctx)
	if err != nil {
		return TemperatureStat{}, err
	}

	var cpuTemp, nvmeTemp float64

	for _, s := range stat {
		switch s.SensorKey {
		case "cpu_thermal":
			cpuTemp = s.Temperature
		case "nvme_composite":
			nvmeTemp = s.Temperature
		}
	}

	return TemperatureStat{
		CPU:  cpuTemp,
		NVME: nvmeTemp,
	}, nil
}
