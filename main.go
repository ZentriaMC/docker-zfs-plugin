package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/coreos/go-systemd/v22/activation"
	"github.com/docker/go-plugins-helpers/volume"
	"github.com/urfave/cli/v2"

	zfsdriver "github.com/ReneHollander/docker-zfs-plugin/zfs"
)

const (
	version         = "3.0.0"
	shutdownTimeout = 10 * time.Second
)

func main() {
	app := &cli.App{
		Name:    "docker-zfs-plugin",
		Usage:   "Docker ZFS Plugin",
		Version: version,
		Flags: []cli.Flag{
			&cli.StringSliceFlag{
				Name:  "dataset-name",
				Usage: "Name of the ZFS dataset to be used. It will be created if it doesn't exist.",
			},
			&cli.StringFlag{
				Name:  "mount-dir",
				Usage: "Path to the directory where datasets will be mounted.",
			},
		},
		Action: Run,
	}

	if err := app.Run(os.Args); err != nil {
		panic(err)
	}
}

// Run runs the driver
func Run(ctx *cli.Context) error {
	if ctx.String("dataset-name") == "" {
		return fmt.Errorf("zfs dataset name is a required field")
	}

	d, err := zfsdriver.NewZfsDriver(ctx.String("mount-dir"), ctx.StringSlice("dataset-name")...)
	if err != nil {
		return err
	}
	h := volume.NewHandler(d)
	errCh := make(chan error)

	listeners, _ := activation.Listeners() // wtf coreos, this funciton never returns errors
	if len(listeners) > 1 {
		slog.Warn("driver does not support multiple sockets")
	}
	if len(listeners) == 0 {
		slog.Info("starting volume handler")
		go func() { errCh <- h.ServeUnix("zfs", 0) }()
	} else {
		l := listeners[0]
		slog.Info("starting volume handler", "listener", l.Addr().String())
		go func() { errCh <- h.Serve(l) }()
	}

	c := make(chan os.Signal, 1)
	defer close(c)
	signal.Notify(c, os.Interrupt)
	signal.Notify(c, syscall.SIGTERM)

	select {
	case err = <-errCh:
		slog.Error("error running handler", "error", err)
		close(errCh)
	case <-c:
	}

	toCtx, toCtxCancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer toCtxCancel()
	if sErr := h.Shutdown(toCtx); sErr != nil {
		err = sErr
		slog.Error("error shutting down handler", "error", err)
	}

	if hErr := <-errCh; hErr != nil && !errors.Is(hErr, http.ErrServerClosed) {
		err = hErr
		slog.Error("error in handler after shutdown", "error", err)
	}

	return err
}
