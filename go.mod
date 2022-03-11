module github.com/ZentriaMC/docker-zfs-plugin

go 1.16

require (
	github.com/Microsoft/go-winio v0.5.2 // indirect
	github.com/c9s/goprocinfo v0.0.0-20210130143923-c95fcf8c64a8
	github.com/clinta/go-zfs v0.0.0-20181025145938-e5fe14d9dcb7
	github.com/coreos/go-systemd v0.0.0-20191104093116-d3cd4ed1dbcf // indirect
	github.com/coreos/go-systemd/v22 v22.3.2
	github.com/cpuguy83/go-md2man/v2 v2.0.1 // indirect
	github.com/docker/go-connections v0.4.0 // indirect
	github.com/docker/go-plugins-helpers v0.0.0-20211224144127-6eecb7beb651
	github.com/moby/locker v1.0.1
	github.com/pkg/errors v0.9.1 // indirect
	github.com/urfave/cli/v2 v2.3.0
	go.uber.org/atomic v1.9.0 // indirect
	go.uber.org/multierr v1.8.0 // indirect
	go.uber.org/zap v1.21.0
	golang.org/x/net v0.0.0-20220225172249-27dd8689420f // indirect
	golang.org/x/sys v0.0.0-20220310020820-b874c991c1a5
)

replace github.com/docker/go-plugins-helpers => github.com/clinta/go-plugins-helpers v0.0.0-20200221140445-4667bb9f0ed5 // for shutdown
