package db

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"

	_ "modernc.org/sqlite"
)

type DB struct {
	*sql.DB
}

func New(dataDir string) (*DB, error) {
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return nil, fmt.Errorf("create data dir: %w", err)
	}

	dbPath := filepath.Join(dataDir, "houniao.db")
	sqlDB, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("open db: %w", err)
	}

	if err := sqlDB.Ping(); err != nil {
		return nil, fmt.Errorf("ping db: %w", err)
	}

	db := &DB{sqlDB}
	if err := db.migrate(); err != nil {
		return nil, fmt.Errorf("migrate: %w", err)
	}

	return db, nil
}

func (db *DB) migrate() error {
	schema := `
		CREATE TABLE IF NOT EXISTS items (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			module_type TEXT NOT NULL DEFAULT 'clipboard',
			content TEXT NOT NULL CHECK(length(content) <= 100000),
			device_id TEXT NOT NULL,
			device_name TEXT NOT NULL DEFAULT '',
			content_hash TEXT NOT NULL,
			created_at INTEGER NOT NULL,
			seq_no INTEGER NOT NULL
		);

		CREATE UNIQUE INDEX IF NOT EXISTS idx_items_hash
			ON items (content_hash, module_type);

		CREATE INDEX IF NOT EXISTS idx_items_module_seq
			ON items (module_type, seq_no);

		CREATE INDEX IF NOT EXISTS idx_items_device_time
			ON items (device_id, created_at);

		CREATE TABLE IF NOT EXISTS devices (
			id TEXT PRIMARY KEY,
			name TEXT NOT NULL,
			platform TEXT NOT NULL DEFAULT '',
			role TEXT NOT NULL DEFAULT 'consumer',
			ip TEXT NOT NULL DEFAULT '',
			port INTEGER NOT NULL DEFAULT 0,
			status TEXT NOT NULL DEFAULT 'offline',
			last_seen INTEGER NOT NULL DEFAULT 0,
			proto_ver INTEGER NOT NULL DEFAULT 1
		);

		CREATE INDEX IF NOT EXISTS idx_devices_status ON devices (status);
		CREATE INDEX IF NOT EXISTS idx_devices_role ON devices (role);

		CREATE TABLE IF NOT EXISTS settings (
			key TEXT PRIMARY KEY,
			value TEXT NOT NULL DEFAULT '',
			updated_at INTEGER NOT NULL DEFAULT 0
		);
		`
	if _, err := db.Exec(schema); err != nil {
		return err
	}

	// 兼容旧库：补充缺失的列
	if err := db.addColumnIfMissing("devices", "role", "TEXT", "'consumer'"); err != nil {
		return fmt.Errorf("add role column: %w", err)
	}
	if err := db.addColumnIfMissing("devices", "platform", "TEXT", "''"); err != nil {
		return fmt.Errorf("add platform column: %w", err)
	}
	if err := db.addColumnIfMissing("devices", "proto_ver", "INTEGER", "1"); err != nil {
		return fmt.Errorf("add proto_ver column: %w", err)
	}
	if err := db.addColumnIfMissing("devices", "ip", "TEXT", "''"); err != nil {
		return fmt.Errorf("add ip column: %w", err)
	}
	if err := db.addColumnIfMissing("devices", "port", "INTEGER", "0"); err != nil {
		return fmt.Errorf("add port column: %w", err)
	}

	// 重建索引（旧库可能因缺失列而创建失败）
	db.Exec("CREATE INDEX IF NOT EXISTS idx_devices_role ON devices (role)")
	db.Exec("CREATE INDEX IF NOT EXISTS idx_devices_status ON devices (status)")

	return nil
}

// addColumnIfMissing 在列不存在时追加一列（SQLite 不支持 ADD COLUMN IF NOT EXISTS）
func (db *DB) addColumnIfMissing(table, col, colType, defaultVal string) error {
	rows, err := db.Query("PRAGMA table_info(" + table + ")")
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		var cid int
		var name, ctype string
		var notNull int
		var dflt sql.NullString
		var pk int
		if err := rows.Scan(&cid, &name, &ctype, &notNull, &dflt, &pk); err != nil {
			return err
		}
		if name == col {
			return nil // 列已存在
		}
	}
	sqlStmt := "ALTER TABLE " + table + " ADD COLUMN " + col + " " + colType
	if defaultVal != "" {
		sqlStmt += " DEFAULT " + defaultVal
	}
	_, err = db.Exec(sqlStmt)
	return err
}
