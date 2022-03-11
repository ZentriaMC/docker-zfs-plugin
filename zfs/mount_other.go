package zfsdriver

import (
	"errors"
	"runtime"
)

func mount(source string, target string, fsType string, flags uintptr, data string) error {
	return errors.New("unsupported platform: " + runtime.GOOS)
}
