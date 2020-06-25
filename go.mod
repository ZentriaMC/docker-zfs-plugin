module github.com/mikroskeem/docker-zfs-plugin

go 1.13

require (
	github.com/Microsoft/go-winio v0.4.14 // indirect
	github.com/c9s/goprocinfo v0.0.0-20200311234719-5750cbd54a3b
	github.com/clinta/go-zfs v0.0.0-20181025145938-e5fe14d9dcb7
	github.com/coreos/go-systemd v0.0.0-20191104093116-d3cd4ed1dbcf
	github.com/cpuguy83/go-md2man/v2 v2.0.0 // indirect
	github.com/docker/go-connections v0.4.0 // indirect
	github.com/docker/go-plugins-helpers v0.0.0-20200102110956-c9a8a2d92ccc
	github.com/urfave/cli v1.22.4
	go.uber.org/zap v1.15.0
	golang.org/x/net v0.0.0-20200625001655-4c5254603344 // indirect
	golang.org/x/sys v0.0.0-20200625212154-ddb9806d33ae // indirect
)

replace github.com/docker/go-plugins-helpers => github.com/clinta/go-plugins-helpers v0.0.0-20200221140445-4667bb9f0ed5 // for shutdown

// https://github.com/coreos/go-systemd/issues/321
replace github.com/coreos/go-systemd => github.com/coreos/go-systemd/v22 v22.0.0
