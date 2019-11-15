package main

import (
	"fmt"
	"log"
	"os"

	"github.com/docker/go-plugins-helpers/volume"
	"github.com/mikroskeem/docker-zfs-plugin/zfs"
	"github.com/urfave/cli"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

const (
	version = "1.0.3"
)

func main() {
	app := cli.NewApp()
	app.Name = "docker-zfs-plugin"
	app.Usage = "Docker ZFS Plugin"
	app.Version = version
	app.Flags = []cli.Flag{
		cli.StringSliceFlag{
			Name:  "dataset-name",
			Usage: "Name of the ZFS dataset to be used. It will be created if it doesn't exist.",
		},
		cli.BoolFlag{
			Name:  "debug",
			Usage: "Whether to run plugin with debugging logging enabled or not",
		},
	}
	app.Action = Run

	err := app.Run(os.Args)
	if err != nil {
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
	defer zap.L().Sync()

	// Redirect native logger to zap debug level
	log.SetPrefix("")
	log.SetFlags(log.Llongfile)
	log.SetOutput(NewZapLogWriter(ZapWriterLevelDebug))

	d, err := zfsdriver.NewZfsDriver(ctx.StringSlice("dataset-name")...)
	if err != nil {
		return err
	}
	h := volume.NewHandler(d)

	zap.L().Info("Ready to serve")
	return h.ServeUnix("zfs", 0)
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

	return nil
}
