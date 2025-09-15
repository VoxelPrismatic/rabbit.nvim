package main

import (
	"strings"

	"github.com/neovim/go-client/nvim/plugin"
)

func hello(args []string) (string, error) {
	return "Hello " + strings.Join(args, " "), nil
}

func main() {
	plugin.Main(func(p *plugin.Plugin) error {
		p.HandleFunction(&plugin.FunctionOptions{Name: "Hello"}, hello)
		return nil
	})
}
