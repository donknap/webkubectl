package localcommand

import (
	"log"
	"syscall"
	"time"

	"github.com/KubeOperator/webkubectl/gotty/server"
)

// Options : close options
type Options struct {
	CloseSignal  int `hcl:"close_signal" flagName:"close-signal" flagSName:"" flagDescribe:"Signal sent to the command process when gotty close it (default: SIGHUP)" default:"1"`
	CloseTimeout int `hcl:"close_timeout" flagName:"close-timeout" flagSName:"" flagDescribe:"Time in seconds to force kill process after client is disconnected (default: -1)" default:"-1"`
}

// Factory : command factory
type Factory struct {
	command string
	argv    []string
	options *Options
	opts    []Option
}

// NewFactory : create a new factory
func NewFactory(command string, argv []string, options *Options) (*Factory, error) {
	opts := []Option{WithCloseSignal(syscall.Signal(options.CloseSignal))}
	if options.CloseTimeout >= 0 {
		opts = append(opts, WithCloseTimeout(time.Duration(options.CloseTimeout)*time.Second))
	}

	return &Factory{
		command: command,
		argv:    argv,
		options: options,
		opts:    opts,
	}, nil
}

// Name : get name of factory
func (factory *Factory) Name() string {
	return "local command"
}

// New : create a new slave
func (factory *Factory) New(params map[string][]string) (server.Slave, error) {
	argv := make([]string, len(factory.argv))
	copy(argv, factory.argv)
	if params["arg"] != nil && len(params["arg"]) > 0 {
		argv = append(argv, params["arg"]...)
	}
	log.Printf("New argv: %#v, params: %#v", argv, params)
	return New(factory.command, argv, factory.opts...)
}
