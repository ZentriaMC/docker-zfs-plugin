package zfsdriver

import (
	"fmt"
	"maps"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"syscall"
	"time"

	zfs "github.com/clinta/go-zfs"
	zfscmd "github.com/clinta/go-zfs/cmd"
	"github.com/docker/go-plugins-helpers/volume"
	"github.com/flytam/filenamify"
	"golang.org/x/exp/slog"
)

// ZfsDriver implements the plugin helpers volume.Driver interface for zfs
type ZfsDriver struct {
	volume.Driver
	mountDir        string
	rootDatasets    []*zfs.Dataset
	mountState      map[string]map[string]bool
	mountStateMutex sync.Mutex
}

// NewZfsDriver returns the plugin driver object
func NewZfsDriver(mountDir string, datasets ...string) (*ZfsDriver, error) {
	// Filter out duplicate datasets to avoid funky behaviour
	rootDatasetMap := make(map[string]bool)
	for _, e := range datasets {
		rootDatasetMap[e] = true
	}
	rootDatasets := slices.Collect(maps.Keys(rootDatasetMap))

	slog.Info("creating zfs driver", "mount-dir", mountDir, "datasets", rootDatasets)

	zd := &ZfsDriver{
		mountDir:        mountDir,
		mountState:      make(map[string]map[string]bool),
		mountStateMutex: sync.Mutex{},
	}
	if len(rootDatasets) < 1 {
		return nil, fmt.Errorf("no datasets specified")
	}

	for _, ds := range rootDatasets {
		if !zfs.DatasetExists(ds) {
			return nil, fmt.Errorf("root dataset %q not found", ds)
		}
		rds, err := zfs.GetDataset(ds)
		if err != nil {
			return nil, fmt.Errorf("error getting root dataset %q: %v", ds, err)
		}
		zd.rootDatasets = append(zd.rootDatasets, rds)
	}

	return zd, nil
}

// isRootDatasetDefined checks if name is a child of any defined root dataset in this driver
// instance.
func (zd *ZfsDriver) isRootDatasetDefined(name string) (isValid bool) {
	isValid = false
	for _, rds := range zd.rootDatasets {
		if strings.HasPrefix(name, rds.Name+"/") {
			isValid = true
			return
		}
	}
	return
}

// Create creates a new zfs dataset for a volume
func (zd *ZfsDriver) Create(req *volume.CreateRequest) error {
	opts := req.Options
	if opts == nil {
		opts = make(map[string]string)
	}
	opts["mountpoint"] = "legacy"

	slog.Info("creating dataset", "name", req.Name, "options", opts)

	// Check root dataset
	if !zd.isRootDatasetDefined(req.Name) {
		return fmt.Errorf("invalid parent dataset")
	}

	if zfs.DatasetExists(req.Name) {
		return fmt.Errorf("volume already exists")
	}

	_, err := zfs.CreateDatasetRecursive(req.Name, opts)
	if err != nil {
		return err
	}

	return nil
}

// List returns a list of zfs volumes on this host
func (zd *ZfsDriver) List() (*volume.ListResponse, error) {
	var vols []*volume.Volume

	for _, rds := range zd.rootDatasets {
		dsl, err := rds.DatasetList()
		if err != nil {
			return nil, err
		}
		for _, ds := range dsl {
			mp, err := zd.getMP(ds.Name)
			if err != nil {
				return nil, err
			}
			vols = append(vols, &volume.Volume{Name: ds.Name, Mountpoint: mp})
		}
	}

	return &volume.ListResponse{Volumes: vols}, nil
}

// Get returns the volume.Volume{} object for the requested volume
// nolint: dupl
func (zd *ZfsDriver) Get(req *volume.GetRequest) (*volume.GetResponse, error) {
	v, err := zd.getVolume(req.Name)
	if err != nil {
		return nil, err
	}

	return &volume.GetResponse{Volume: v}, nil
}

func (zd *ZfsDriver) getVolume(name string) (*volume.Volume, error) {
	ds, err := zfs.GetDataset(name)
	if err != nil {
		return nil, err
	}

	mp, err := zd.getMP(ds.Name)
	if err != nil {
		return nil, err
	}

	ts, err := ds.GetCreation()
	if err != nil {
		slog.Warn("failed to get creation property from zfs dataset", "error", err)
		return &volume.Volume{Name: name, Mountpoint: mp}, nil
	}

	return &volume.Volume{Name: name, Mountpoint: mp, CreatedAt: ts.Format(time.RFC3339)}, nil
}

func Chunks(s string, chunkSize int) []string {
	if len(s) == 0 {
		return nil
	}
	if chunkSize >= len(s) {
		return []string{s}
	}
	var chunks []string = make([]string, 0, (len(s)-1)/chunkSize+1)
	currentLen := 0
	currentStart := 0
	for i := range s {
		if currentLen == chunkSize {
			chunks = append(chunks, s[currentStart:i])
			currentLen = 0
			currentStart = i
		}
		currentLen++
	}
	chunks = append(chunks, s[currentStart:])
	return chunks
}

func (zd *ZfsDriver) getMP(name string) (string, error) {
	safeName, err := filenamify.Filenamify(name, filenamify.Options{Replacement: "_", MaxLength: 10000})
	if err != nil {
		return "", err
	}
	parts := []string{zd.mountDir}
	parts = append(parts, Chunks(safeName, 200)...)
	return filepath.Join(parts...), nil
}

// Remove destroys a zfs dataset for a volume
func (zd *ZfsDriver) Remove(req *volume.RemoveRequest) error {
	slog.Info("removing volume", "dataset", req.Name)

	// Check root dataset
	if !zd.isRootDatasetDefined(req.Name) {
		return fmt.Errorf("invalid parent dataset")
	}

	if _, err := zfs.GetDataset(req.Name); err != nil {
		return err
	}

	err := zfscmd.Destroy(req.Name, &zfscmd.DestroyOpts{
		DestroyChildren: false,
		DestroyClones:   false,
		ForceUnmount:    false,
		Defer:           false,
	})
	if err != nil {
		zfsErr := err.(*zfscmd.ZFSError)
		return fmt.Errorf("failed to destroy volume %q: %s", req.Name, zfsErr.Stderr)
	}
	return nil
}

// Path returns the mountpoint of a volume
func (zd *ZfsDriver) Path(req *volume.PathRequest) (*volume.PathResponse, error) {
	mp, err := zd.getMP(req.Name)
	if err != nil {
		return nil, err
	}

	return &volume.PathResponse{Mountpoint: mp}, nil
}

// Mount returns the mountpoint of the zfs volume
func (zd *ZfsDriver) Mount(req *volume.MountRequest) (*volume.MountResponse, error) {
	mp, err := zd.getMP(req.Name)
	if err != nil {
		return nil, err
	}

	zd.mountStateMutex.Lock()
	defer zd.mountStateMutex.Unlock()

	_, has := zd.mountState[mp]
	if has {
		slog.Info("dataset already mounted. doing nothing.", "request", req.ID, "dataset", req.Name, "mountpoint", mp)
	} else {
		slog.Info("mounting volume", "request", req.ID, "dataset", req.Name, "mountpoint", mp)
		err = os.MkdirAll(mp, 0700)
		if err != nil {
			return nil, err
		}
		err = syscall.Mount(req.Name, mp, "zfs", 0, "")
		if err != nil {
			return nil, err
		}
		zd.mountState[mp] = make(map[string]bool)
	}

	zd.mountState[mp][req.ID] = true

	return &volume.MountResponse{Mountpoint: mp}, nil
}

// Unmount does nothing because a zfs dataset need not be unmounted
func (zd *ZfsDriver) Unmount(req *volume.UnmountRequest) error {
	mp, err := zd.getMP(req.Name)
	if err != nil {
		return err
	}
	zd.mountStateMutex.Lock()
	defer zd.mountStateMutex.Unlock()

	_, has := zd.mountState[mp]
	if !has {
		return fmt.Errorf("cannot unmount dataset %q for request %q: dataset has not been mounted previously", req.Name, req.ID)
	}
	_, has = zd.mountState[mp][req.ID]
	if !has {
		return fmt.Errorf("cannot unmount dataset %q for request %q: the given request has not mounted the dataset previously", req.Name, req.ID)
	}

	delete(zd.mountState[mp], req.ID)
	if len(zd.mountState[mp]) > 0 {
		slog.Info("dataset is still mounted. not unmounting", "request", req.ID, "dataset", req.Name, "mountpoint", mp)
	}
	if len(zd.mountState[mp]) == 0 {
		delete(zd.mountState, mp)

		slog.Info("unmounting volume", "request", req.ID, "dataset", req.Name, "mountpoint", mp)

		err = syscall.Unmount(mp, 0)
		if err != nil {
			return err
		}
		err = os.Remove(mp)
		if err != nil {
			return err
		}
	}

	return nil
}

// Capabilities sets the scope to local as this is a local only driver
func (zd *ZfsDriver) Capabilities() *volume.CapabilitiesResponse {
	return &volume.CapabilitiesResponse{Capabilities: volume.Capability{Scope: "local"}}
}
