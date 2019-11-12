package main

import "go.uber.org/zap"

const (
	ZapWriterLevelDebug int = iota
	ZapWriterLevelInfo
	ZapWriterLevelWarn
	ZapWriterLevelError
)

type ZapLogWriter struct {
	level int
}

func NewZapLogWriter(level int) *ZapLogWriter {
	return &ZapLogWriter{
		level: level,
	}
}

func (w *ZapLogWriter) Write(p []byte) (n int, err error) {
	switch w.level {
	case ZapWriterLevelDebug:
		zap.L().Debug(string(p))
	case ZapWriterLevelInfo:
		zap.L().Info(string(p))
	case ZapWriterLevelWarn:
		zap.L().Warn(string(p))
	case ZapWriterLevelError:
		zap.L().Error(string(p))
	}
	return len(p), nil
}
