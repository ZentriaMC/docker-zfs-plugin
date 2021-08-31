package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/coreos/go-systemd/v22/activation"
	"github.com/docker/go-plugins-helpers/volume"
	"github.com/urfave/cli/v2"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"

	zfsdriver "github.com/ZentriaMC/docker-zfs-plugin/zfs"
)

const (
	version         = "1.0.5"
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
			&cli.BoolFlag{
				Name:    "debug",
				Usage:   "Whether to run plugin with debugging logging enabled or not",
				Aliases: []string{"verbose"},
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

	// Configure logging
	if err := configureLogging(ctx.Bool("debug")); err != nil {
		return err
	}
	defer func() { _ = zap.L().Sync() }()

	d, err := zfsdriver.NewZfsDriver(ctx.StringSlice("dataset-name")...)
	if err != nil {
		return err
	}
	h := volume.NewHandler(d)
	errCh := make(chan error)

	listeners, _ := activation.Listeners() // wtf coreos, this funciton never returns errors
	if len(listeners) > 1 {
		zap.L().Warn("driver does not support multiple sockets")
	}
	if len(listeners) == 0 {
		zap.L().Debug("launching volume handler.")
		go func() { errCh <- h.ServeUnix("zfs", 0) }()
	} else {
		l := listeners[0]
		zap.L().Debug("launching volume handler", zap.String("listener", l.Addr().String()))
		go func() { errCh <- h.Serve(l) }()
	}

	c := make(chan os.Signal, 1)
	defer close(c)
	signal.Notify(c, os.Interrupt)
	signal.Notify(c, syscall.SIGTERM)

	select {
	case err = <-errCh:
		zap.L().Error("error running handler", zap.Error(err))
		close(errCh)
	case <-c:
	}

	toCtx, toCtxCancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer toCtxCancel()
	if sErr := h.Shutdown(toCtx); sErr != nil {
		err = sErr
		zap.L().Error("error shutting down handler", zap.Error(err))
	}

	if hErr := <-errCh; hErr != nil && !errors.Is(hErr, http.ErrServerClosed) {
		err = hErr
		zap.L().Error("error in handler after shutdown", zap.Error(err))
	}

	return err
}

func configureLogging(debug bool) error {
	var cfg zap.Config

	if debug {
		cfg = zap.NewDevelopmentConfig()
		cfg.Level.SetLevel(zapcore.DebugLevel)
	} else {
		cfg = zap.NewProductionConfig()
		cfg.Level.SetLevel(zapcore.InfoLevel)
	}

	cfg.Encoding = "console"
	cfg.OutputPaths = []string{
		"stdout",
	}

	logger, err := cfg.Build()
	if err != nil {
		return err
	}

	zap.ReplaceGlobals(logger)
	if debug {
		zap.L().Debug("debug logging enabled")
	}

	// Redirect native logger to zap debug level
	if _, err := zap.RedirectStdLogAt(logger, zapcore.DebugLevel); err != nil {
		return err
	}

	return nil
}
