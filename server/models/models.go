package models

import "time"

// ClipboardItem 剪贴板记录
type ClipboardItem struct {
	ID          int64     `json:"id"`
	Content     string    `json:"content"`
	DeviceID    string    `json:"device_id"`
	DeviceName  string    `json:"device_name"`
	ContentHash string    `json:"content_hash"`
	CreatedAt   time.Time `json:"created_at"`
	SeqNo       int64     `json:"seq_no"`
}

// DeviceInfo 设备信息
type DeviceInfo struct {
	ID       string    `json:"id"`
	Name     string    `json:"name"`
	Platform string    `json:"platform"`
	Role     string    `json:"role"`
	IP       string    `json:"ip"`
	Port     int       `json:"port"`
	Status   string    `json:"status"`
	LastSeen time.Time `json:"last_seen"`
	ProtoVer int       `json:"proto_ver"`
}

// Setting 用户配置
type Setting struct {
	Key       string    `json:"key"`
	Value     string    `json:"value"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Message 统一消息结构
type Message struct {
	Type string      `json:"type"`
	ID   string      `json:"id"`
	Time int64       `json:"time"`
	Data interface{} `json:"data,omitempty"`
}

type PullHistoryData struct {
	ModuleType string `json:"module_type"`
	SinceSeqNo int64  `json:"since_seq_no"`
}

type PullAckData struct {
	ModuleType string `json:"module_type"`
	Items      []Item `json:"items"`
}

type AckData struct {
	ReqID  string `json:"req_id"`
	Status int    `json:"status"`
	Detail string `json:"detail,omitempty"`
}

// Item 平台通用同步条目
type Item struct {
	ID          int64  `json:"id"`
	ModuleType  string `json:"module_type"`
	Content     string `json:"content"`
	DeviceID    string `json:"device_id"`
	DeviceName  string `json:"device_name"`
	ContentHash string `json:"content_hash"`
	CreatedAt   int64  `json:"created_at"`
	SeqNo       int64  `json:"seq_no"`
}

// DeviceRole 设备角色
const (
	RoleConsumer   = "consumer"
	RoleMaintainer = "maintainer"
)

// 状态码
const (
	StatusOK              = 0
	StatusBadPayload      = 100
	StatusRateLimited     = 200
	StatusConflict        = 300
	StatusVersionMismatch = 400
	StatusInternalError   = 500
)
