package models

// ItemPushData 模块推送数据
type ItemPushData struct {
	ModuleType string `json:"module_type"`
	Content    string `json:"content"`
}

// ItemBroadcastData 广播数据
type ItemBroadcastData struct {
	ModuleType string `json:"module_type"`
	Content    string `json:"content"`
	DeviceID   string `json:"device_id"`
	DeviceName string `json:"device_name"`
	SeqNo      int64  `json:"seq_no"`
	CreatedAt  int64  `json:"created_at"`
}
