package config

import "os"

type Config struct {
	Port        string
	DataDir     string
	ServiceName string
}

func Load() *Config {
	port := getEnv("HOUNIAO_PORT", "9527")
	dataDir := getEnv("HOUNIAO_DATA_DIR", "./data")
	serviceName := getEnv("HOUNIAO_SERVICE_NAME", "houniao")

	return &Config{
		Port:        port,
		DataDir:     dataDir,
		ServiceName: serviceName,
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
