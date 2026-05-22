package main

import (
	"fmt"
	"log"
	"net/http"

	"houniao/server/config"
	"houniao/server/db"
	"houniao/server/discovery"
	"houniao/server/message"
	"houniao/server/transport"
)

func main() {
	cfg := config.Load()

	database, err := db.New(cfg.DataDir)
	if err != nil {
		log.Fatalf("init db: %v", err)
	}
	defer database.Close()

	// 启动时清理旧在线状态
	if err := database.StartupClean(); err != nil {
		log.Printf("startup clean: %v", err)
	}

	// mDNS 广播
	mdns, err := discovery.NewMDNS(cfg.ServiceName, cfg.Port)
	if err != nil {
		log.Printf("mDNS init failed (non-fatal): %v", err)
	} else {
		go mdns.Serve()
		defer mdns.Shutdown()
	}

	// 消息路由
	router := message.NewRouter(database)

	// WebSocket 服务
	wsServer := transport.NewWSServer(cfg.Port, router, database)
	http.Handle("/ws", wsServer.Handler())
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	addr := fmt.Sprintf("0.0.0.0:%s", cfg.Port)
	log.Printf("houniao server listening on %s", addr)
	log.Printf("data dir: %s", cfg.DataDir)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
