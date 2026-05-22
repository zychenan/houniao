package message

import (
	"log"

	"houniao/server/models"
)

// sendTo sends a message to a single device.
func (r *Router) sendTo(deviceID string, msg models.Message) {
	conn, ok := r.conns.get(deviceID)
	if !ok {
		return
	}
	if err := conn.WriteJSON(msg); err != nil {
		log.Printf("send to %s failed: %v", deviceID, err)
	}
}

// broadcast sends a message to all devices except the one with excludeID.
func (r *Router) broadcast(msg models.Message, excludeID string) {
	for _, conn := range r.conns.allExcept(excludeID) {
		if err := conn.WriteJSON(msg); err != nil {
			log.Printf("broadcast to %s failed: %v", conn.DeviceID(), err)
		}
	}
}

// broadcastAll sends a message to every connected device.
func (r *Router) broadcastAll(msg models.Message) {
	for _, conn := range r.conns.all() {
		if err := conn.WriteJSON(msg); err != nil {
			log.Printf("broadcast to %s failed: %v", conn.DeviceID(), err)
		}
	}
}
