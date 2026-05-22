package discovery

import (
	"fmt"
	"log"
	"net"
	"os"
	"strconv"

	"github.com/grandcat/zeroconf"
)

type MDNS struct {
	server *zeroconf.Server
}

func NewMDNS(serviceName, port string) (*MDNS, error) {
	_, _ = os.Hostname()

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return nil, err
	}

	var ips []net.IP
	for _, addr := range addrs {
		if ipNet, ok := addr.(*net.IPNet); ok && !ipNet.IP.IsLoopback() {
			if ipNet.IP.To4() != nil {
				ips = append(ips, ipNet.IP)
			}
		}
	}

	portInt, err := strconv.Atoi(port)
	if err != nil {
		return nil, fmt.Errorf("invalid port: %w", err)
	}

	server, err := zeroconf.Register(
		serviceName,
		"_houniao._tcp",
		"local.",
		portInt,
		[]string{"txtv=1", "path=/ws"},
		nil,
	)
	if err != nil {
		return nil, err
	}

	log.Printf("mDNS: advertising as %s._houniao._tcp.local on port %s, ips: %v", serviceName, port, ips)

	return &MDNS{server: server}, nil
}

func (m *MDNS) Serve() {
	select {}
}

func (m *MDNS) Shutdown() {
	if m.server != nil {
		m.server.Shutdown()
	}
}
