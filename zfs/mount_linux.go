package zfsdriver

import (
	"golang.org/x/sys/unix"
)

func mount(source string, target string, fsType string, flags uintptr, data string) error {
	return unix.Mount(source, target, fsType, flags, data)
}
