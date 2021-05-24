module github.com/ZentriaMC/docker-zfs-plugin

go 1.16

require (
	github.com/Microsoft/go-winio v0.5.0 // indirect
	github.com/c9s/goprocinfo v0.0.0-20210130143923-c95fcf8c64a8
	github.com/clinta/go-zfs v0.0.0-20181025145938-e5fe14d9dcb7
	github.com/coreos/go-systemd v0.0.0-20191104093116-d3cd4ed1dbcf // indirect
	github.com/coreos/go-systemd/v22 v22.3.2
	github.com/cpuguy83/go-md2man/v2 v2.0.0 // indirect
	github.com/docker/go-connections v0.4.0 // indirect
	github.com/docker/go-plugins-helpers v0.0.0-20200102110956-c9a8a2d92ccc
	github.com/russross/blackfriday/v2 v2.1.0 // indirect
	github.com/urfave/cli v1.22.5
	go.uber.org/multierr v1.7.0 // indirect
	go.uber.org/zap v1.16.0
	golang.org/x/net v0.0.0-20210521195947-fe42d452be8f // indirect
	golang.org/x/sys v0.0.0-20210521203332-0cec03c779c1 // indirect
)

replace github.com/docker/go-plugins-helpers => github.com/clinta/go-plugins-helpers v0.0.0-20200221140445-4667bb9f0ed5 // for shutdown
