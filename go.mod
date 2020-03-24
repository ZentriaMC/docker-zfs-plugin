module github.com/mikroskeem/docker-zfs-plugin

go 1.13

require (
	github.com/Microsoft/go-winio v0.4.14 // indirect
	github.com/c9s/goprocinfo v0.0.0-20200311234719-5750cbd54a3b
	github.com/clinta/go-zfs v0.0.0-20181025145938-e5fe14d9dcb7
	github.com/coreos/go-systemd v0.0.0-20191104093116-d3cd4ed1dbcf // indirect
	github.com/docker/go-connections v0.4.0 // indirect
	github.com/docker/go-plugins-helpers v0.0.0-20200102110956-c9a8a2d92ccc
	github.com/urfave/cli v1.22.3
	go.uber.org/zap v1.14.1
)

// https://github.com/coreos/go-systemd/issues/321
replace github.com/coreos/go-systemd => github.com/coreos/go-systemd/v22 v22.0.0
