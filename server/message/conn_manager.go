package message

import "sync"

// WSConn is the interface a WebSocket connection must satisfy.
type WSConn interface {
	WriteJSON(v interface{}) error
	DeviceID() string
}

type connManager struct {
	mu    sync.RWMutex
	conns map[string]WSConn // deviceID -> conn
}

func newConnManager() *connManager {
	return &connManager{
		conns: make(map[string]WSConn),
	}
}

// register adds a connection. Caller must NOT hold the mutex.
func (cm *connManager) register(deviceID string, conn WSConn) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	cm.conns[deviceID] = conn
}

// remove deletes a connection. Caller must NOT hold the mutex.
func (cm *connManager) remove(deviceID string) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	delete(cm.conns, deviceID)
}

// get returns a single connection by device ID (read-locked snapshot).
func (cm *connManager) get(deviceID string) (WSConn, bool) {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	conn, ok := cm.conns[deviceID]
	return conn, ok
}

// all returns a snapshot of all connections (read-locked).
func (cm *connManager) all() []WSConn {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	result := make([]WSConn, 0, len(cm.conns))
	for _, conn := range cm.conns {
		result = append(result, conn)
	}
	return result
}

// allExcept returns a snapshot of all connections except the given device ID.
func (cm *connManager) allExcept(excludeID string) []WSConn {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	result := make([]WSConn, 0, len(cm.conns))
	for id, conn := range cm.conns {
		if id != excludeID {
			result = append(result, conn)
		}
	}
	return result
}
