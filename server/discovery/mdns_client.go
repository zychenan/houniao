package discovery

import (
	"fmt"

	"github.com/grandcat/zeroconf"
)

func ResolveMDNS(serviceName string) (string, error) {
	resolver, err := zeroconf.NewResolver(nil)
	if err != nil {
		return "", err
	}

	entries := make(chan *zeroconf.ServiceEntry)
	go func() {
		err := resolver.Browse(nil, "_houniao._tcp", "local.", entries)
		if err != nil {
			close(entries)
		}
	}()

	for entry := range entries {
		if entry.ServiceInstanceName() == fmt.Sprintf("%s._houniao._tcp.local.", serviceName) {
			if len(entry.AddrIPv4) > 0 {
				return fmt.Sprintf("ws://%s:%d/ws", entry.AddrIPv4[0].String(), entry.Port), nil
			}
		}
	}

	return "", fmt.Errorf("service not found: %s", serviceName)
}
