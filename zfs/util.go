package zfsdriver

import (
	"crypto/sha256"
	"encoding/hex"
)

func hex256(name string) string {
	b := sha256.Sum256([]byte(name))
	return hex.EncodeToString(b[:])
}
