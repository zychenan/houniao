package db

import (
	"crypto/sha256"
	"fmt"
	"time"

	"houniao/server/models"
)

// SaveItem 保存一条同步记录，返回 seq_no
func (db *DB) SaveItem(moduleType, content, deviceID, deviceName string) (int64, error) {
	hash := fmt.Sprintf("%x", sha256.Sum256([]byte(content)))
	now := time.Now().UnixMilli()

	result, err := db.Exec(`
		INSERT INTO items (module_type, content, device_id, device_name, content_hash, created_at, seq_no)
		VALUES (?, ?, ?, ?, ?, ?, (SELECT COALESCE(MAX(seq_no), 0) + 1 FROM items WHERE module_type = ?))
	`, moduleType, content, deviceID, deviceName, hash, now, moduleType)
	if err != nil {
		return 0, err
	}
	id, err := result.LastInsertId()
	if err != nil {
		return 0, err
	}
	// 查询刚写入的 seq_no
	var seqNo int64
	err = db.QueryRow("SELECT seq_no FROM items WHERE id = ?", id).Scan(&seqNo)
	return seqNo, err
}

// ExistsByHash 根据内容哈希+模块类型去重
func (db *DB) ExistsByHash(moduleType, content string) (bool, error) {
	h := fmt.Sprintf("%x", sha256.Sum256([]byte(content)))
	var count int
	err := db.QueryRow(
		"SELECT COUNT(*) FROM items WHERE module_type = ? AND content_hash = ?",
		moduleType, h,
	).Scan(&count)
	return count > 0, err
}

// PullSince 取增量数据
func (db *DB) PullSince(moduleType string, sinceSeqNo int64) ([]models.Item, error) {
	rows, err := db.Query(`
		SELECT id, module_type, content, device_id, device_name, content_hash, created_at, seq_no
		FROM items WHERE module_type = ? AND seq_no > ?
		ORDER BY seq_no ASC LIMIT 100
	`, moduleType, sinceSeqNo)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Item
	for rows.Next() {
		var item models.Item
		if err := rows.Scan(&item.ID, &item.ModuleType, &item.Content, &item.DeviceID, &item.DeviceName,
			&item.ContentHash, &item.CreatedAt, &item.SeqNo); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, nil
}

// CleanExpired 清理过期记录
func (db *DB) CleanExpired(moduleType string, retentionDays int) error {
	cutoff := time.Now().AddDate(0, 0, -retentionDays).UnixMilli()
	_, err := db.Exec("DELETE FROM items WHERE module_type = ? AND created_at < ?",
		moduleType, cutoff)
	return err
}

// ListMaintainers 查在线维护设备
func (db *DB) ListMaintainers() ([]models.DeviceInfo, error) {
	rows, err := db.Query(`
		SELECT id, name, platform, role, ip, port, status, last_seen, proto_ver
		FROM devices WHERE role='maintainer' AND status='online'
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var devices []models.DeviceInfo
	for rows.Next() {
		var d models.DeviceInfo
		var ls int64
		if err := rows.Scan(&d.ID, &d.Name, &d.Platform, &d.Role,
			&d.IP, &d.Port, &d.Status, &ls, &d.ProtoVer); err != nil {
			return nil, err
		}
		d.LastSeen = time.UnixMilli(ls)
		devices = append(devices, d)
	}
	return devices, nil
}

// GetDeviceName 查设备名
func (db *DB) GetDeviceName(deviceID string) string {
	var name string
	if err := db.QueryRow("SELECT name FROM devices WHERE id = ?", deviceID).Scan(&name); err != nil {
		return deviceID
	}
	return name
}

// UpsertDevice 登记或更新设备
func (db *DB) UpsertDevice(device *models.DeviceInfo) error {
	now := time.Now().UnixMilli()
	_, err := db.Exec(`
		INSERT OR REPLACE INTO devices (id, name, platform, role, ip, port, status, last_seen, proto_ver)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, device.ID, device.Name, device.Platform, device.Role, device.IP, device.Port, device.Status, now, device.ProtoVer)
	return err
}

// UpdateDeviceStatus 只更新设备在线状态 + last_seen，不覆盖其他字段
func (db *DB) UpdateDeviceStatus(deviceID, status string) error {
	now := time.Now().UnixMilli()
	_, err := db.Exec("UPDATE devices SET status = ?, last_seen = ? WHERE id = ?",
		status, now, deviceID)
	return err
}

// MarkDeviceOffline 标记设备离线
func (db *DB) MarkDeviceOffline(deviceID string) error {
	_, err := db.Exec("UPDATE devices SET status = 'offline' WHERE id = ?", deviceID)
	return err
}

// ListOnlineDevices 列出在线设备
func (db *DB) ListOnlineDevices() ([]models.DeviceInfo, error) {
	rows, err := db.Query("SELECT id, name, platform, role, ip, port, status, last_seen, proto_ver FROM devices WHERE status = 'online'")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var devices []models.DeviceInfo
	for rows.Next() {
		var d models.DeviceInfo
		var lastSeen int64
		if err := rows.Scan(&d.ID, &d.Name, &d.Platform, &d.Role, &d.IP, &d.Port, &d.Status, &lastSeen, &d.ProtoVer); err != nil {
			return nil, err
		}
		d.LastSeen = time.UnixMilli(lastSeen)
		devices = append(devices, d)
	}
	return devices, nil
}

// StartupClean 启动时把所有设备标为离线
func (db *DB) StartupClean() error {
	_, err := db.Exec("UPDATE devices SET status = 'offline'")
	return err
}

// GetSetting 读取设置
func (db *DB) GetSetting(key string) (string, error) {
	var value string
	err := db.QueryRow("SELECT value FROM settings WHERE key = ?", key).Scan(&value)
	if err != nil {
		return "", err
	}
	return value, nil
}

// SetSetting 修改设置
func (db *DB) SetSetting(key, value string) error {
	now := time.Now().UnixMilli()
	_, err := db.Exec("INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES (?, ?, ?)", key, value, now)
	return err
}

// GetAllSettings 读取全部设置
func (db *DB) GetAllSettings() (map[string]string, error) {
	rows, err := db.Query("SELECT key, value FROM settings")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	settings := make(map[string]string)
	for rows.Next() {
		var k, v string
		if err := rows.Scan(&k, &v); err != nil {
			return nil, err
		}
		settings[k] = v
	}
	return settings, nil
}
