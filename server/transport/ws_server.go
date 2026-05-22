package transport

import (
	"encoding/json"
	"log"
	"net/http"

	"golang.org/x/net/websocket"

	"houniao/server/db"
	"houniao/server/message"
	"houniao/server/models"
)

type wsConn struct {
	ws       *websocket.Conn
	deviceID string
}

func (w *wsConn) WriteJSON(v interface{}) error {
	return websocket.JSON.Send(w.ws, v)
}

func (w *wsConn) DeviceID() string {
	return w.deviceID
}

type WSServer struct {
	router *message.Router
	db     *db.DB
}

func NewWSServer(port string, router *message.Router, database *db.DB) *WSServer {
	return &WSServer{router: router, db: database}
}

func (s *WSServer) Handler() http.Handler {
	return &websocket.Server{
		Handshake: func(config *websocket.Config, req *http.Request) error {
			return nil
		},
		Handler: func(ws *websocket.Conn) {
			s.handle(ws)
		},
	}
}

func (s *WSServer) handle(ws *websocket.Conn) {
	// 首条消息作为 version_nego
	var raw []byte
	if err := websocket.Message.Receive(ws, &raw); err != nil {
		log.Printf("read version_nego: %v", err)
		return
	}

	var nego struct {
		Type     string `json:"type"`
		DeviceID string `json:"device_id"`
		Platform string `json:"platform"`
		Name     string `json:"name"`
	}
	if err := jsonTo(raw, &nego); err != nil || nego.DeviceID == "" {
		log.Printf("bad version_nego")
		return
	}

	deviceID := nego.DeviceID
	r := ws.Request()

	// 登记设备
	if err := s.db.UpsertDevice(&models.DeviceInfo{
		ID:       deviceID,
		Name:     nego.Name,
		Platform: nego.Platform,
		IP:       r.RemoteAddr,
		Status:   "online",
		ProtoVer: 1,
	}); err != nil {
		log.Printf("upsert device %s: %v", deviceID, err)
	}

	wc := &wsConn{ws: ws, deviceID: deviceID}
	s.router.RegisterConn(deviceID, wc)
	defer func() {
		s.router.RemoveConn(deviceID)
		ws.Close()
	}()

	log.Printf("device connected: %s (%s)", nego.Name, deviceID)

	// 读取循环
	for {
		var rawMsg []byte
		if err := websocket.Message.Receive(ws, &rawMsg); err != nil {
			log.Printf("read from %s: %v", deviceID, err)
			return
		}
		s.router.HandleMessage(rawMsg, deviceID)
	}
}

func jsonTo(raw []byte, v interface{}) error {
	return json.Unmarshal(raw, v)
}
