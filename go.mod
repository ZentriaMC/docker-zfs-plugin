module github.com/mikroskeem/docker-zfs-plugin

go 1.13

require (
	github.com/Microsoft/go-winio v0.4.14 // indirect
	github.com/c9s/goprocinfo v0.0.0-20190309065803-0b2ad9ac246b
	github.com/clinta/go-zfs v0.0.0-20181025145938-e5fe14d9dcb7
	github.com/coreos/go-systemd v0.0.0-00010101000000-000000000000 // indirect
	github.com/docker/go-connections v0.4.0 // indirect
	github.com/docker/go-plugins-helpers v0.0.0-20181025120712-1e6269c305b8
	github.com/urfave/cli v1.22.1
	go.uber.org/zap v1.12.0
	golang.org/x/net v0.0.0-20191109021931-daa7c04131f5 // indirect
)

// https://github.com/coreos/go-systemd/issues/321
replace github.com/coreos/go-systemd => github.com/coreos/go-systemd/v22 v22.0.0
