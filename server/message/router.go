package message

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"houniao/server/db"
	"houniao/server/models"
)

type Router struct {
	db   *db.DB
	conns *connManager
}

func NewRouter(database *db.DB) *Router {
	return &Router{
		db:    database,
		conns: newConnManager(),
	}
}

// RegisterConn 设备上线，注册连接
func (r *Router) RegisterConn(deviceID string, conn WSConn) {
	r.conns.register(deviceID, conn)
	r.broadcastDeviceList()
}

// RemoveConn 设备离线，移除连接
func (r *Router) RemoveConn(deviceID string) {
	r.conns.remove(deviceID)
	r.db.MarkDeviceOffline(deviceID)
	r.broadcastDeviceList()
}

// HandleMessage 处理收到的消息
func (r *Router) HandleMessage(raw []byte, senderID string) {
	var msg models.Message
	if err := json.Unmarshal(raw, &msg); err != nil {
		log.Printf("bad message from %s: %v", senderID, err)
		return
	}

	if msg.Type == "" || msg.ID == "" {
		log.Printf("missing type or id from %s", senderID)
		return
	}

	switch msg.Type {
	case "item_push":
		r.handleItemPush(&msg, senderID)
	case "pull_history":
		r.handlePullHistory(&msg, senderID)
	case "config_upd":
		r.handleConfigUpdate(&msg)
	case "heartbeat":
		r.db.UpdateDeviceStatus(senderID, "online")
	default:
		log.Printf("unknown message type: %s", msg.Type)
	}
}

func (r *Router) handleItemPush(msg *models.Message, senderID string) {
	var data models.ItemPushData
	if err := convertData(msg.Data, &data); err != nil {
		r.reply(msg.ID, senderID, models.StatusBadPayload, "invalid data")
		return
	}

	if data.ModuleType == "" {
		data.ModuleType = "clipboard"
	}
	if len(data.Content) == 0 {
		r.reply(msg.ID, senderID, models.StatusBadPayload, "empty content")
		return
	}
	if len(data.Content) > 100000 {
		r.reply(msg.ID, senderID, models.StatusBadPayload, "content too long")
		return
	}

	exists, err := r.db.ExistsByHash(data.ModuleType, data.Content)
	if err == nil && exists {
		r.reply(msg.ID, senderID, models.StatusOK, "")
		return
	}

	// 查 sender 设备名
	deviceName := r.db.GetDeviceName(senderID)

	seqNo, err := r.db.SaveItem(data.ModuleType, data.Content, senderID, deviceName)
	if err != nil {
		log.Printf("save item: %v", err)
		r.reply(msg.ID, senderID, models.StatusInternalError, "save failed")
		return
	}

	r.reply(msg.ID, senderID, models.StatusOK, "")

	// 广播给其他设备
	broadcast := models.Message{
		Type: "item_broadcast",
		ID:   msg.ID,
		Time: time.Now().UnixMilli(),
		Data: models.ItemBroadcastData{
			ModuleType: data.ModuleType,
			Content:    data.Content,
			DeviceID:   senderID,
			DeviceName: deviceName,
			SeqNo:      seqNo,
			CreatedAt:  time.Now().UnixMilli(),
		},
	}
	r.broadcast(broadcast, senderID)
}

func (r *Router) handlePullHistory(msg *models.Message, senderID string) {
	var data models.PullHistoryData
	if err := convertData(msg.Data, &data); err != nil {
		r.reply(msg.ID, senderID, models.StatusBadPayload, "invalid data")
		return
	}

	if data.ModuleType == "" {
		data.ModuleType = "clipboard"
	}

	items, err := r.db.PullSince(data.ModuleType, data.SinceSeqNo)
	if err != nil {
		log.Printf("pull history: %v", err)
		r.reply(msg.ID, senderID, models.StatusInternalError, "pull failed")
		return
	}

	if items == nil {
		items = []models.Item{}
	}

	ack := models.Message{
		Type: "pull_ack",
		ID:   msg.ID,
		Time: time.Now().UnixMilli(),
		Data: models.PullAckData{
			ModuleType: data.ModuleType,
			Items:      items,
		},
	}
	r.sendTo(senderID, ack)
}

func (r *Router) handleConfigUpdate(msg *models.Message) {
	raw, err := json.Marshal(msg.Data)
	if err != nil {
		log.Printf("config_upd marshal: %v", err)
		return
	}
	var data map[string]string
	if err := json.Unmarshal(raw, &data); err != nil {
		log.Printf("config_upd unmarshal: %v", err)
		return
	}

	for k, v := range data {
		if err := r.db.SetSetting(k, v); err != nil {
			log.Printf("set setting %s: %v", k, err)
		}
	}
}

func (r *Router) reply(reqID, deviceID string, status int, detail string) {
	ack := models.Message{
		Type: "ack",
		ID:   reqID,
		Time: time.Now().UnixMilli(),
		Data: models.AckData{ReqID: reqID, Status: status, Detail: detail},
	}
	r.sendTo(deviceID, ack)
}

func (r *Router) broadcastDeviceList() {
	devices, err := r.db.ListOnlineDevices()
	if err != nil {
		log.Printf("list devices: %v", err)
		return
	}
	msg := models.Message{
		Type: "device_list",
		ID:   fmt.Sprintf("dl_%d", time.Now().UnixNano()),
		Time: time.Now().UnixMilli(),
		Data: devices,
	}
	r.broadcastAll(msg)
}

func convertData(src, dst interface{}) error {
	raw, err := json.Marshal(src)
	if err != nil {
		return err
	}
	return json.Unmarshal(raw, dst)
}
