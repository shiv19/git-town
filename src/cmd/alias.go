package cmd

import (
	"fmt"
	"strconv"

	"github.com/git-town/git-town/src/cli"
	"github.com/git-town/git-town/src/git"
	"github.com/spf13/cobra"
)

var aliasCommand = &cobra.Command{
	Use:   "alias (true | false)",
	Short: "Adds or removes default global aliases",
	Long: `Adds or removes default global aliases

Global aliases make Git Town commands feel like native Git commands.
When enabled, you can run "git hack" instead of "git town hack".

Does not overwrite existing aliases.

This can conflict with other tools that also define Git aliases.`,
	Run: func(cmd *cobra.Command, args []string) {
		toggle, err := strconv.ParseBool(args[0])
		if err != nil {
			cli.Exit(fmt.Errorf(`invalid argument %q. Please provide either "true" or "false"`, args[0]))
		}
		var commandsToAlias = []string{
			"append",
			"hack",
			"kill",
			"new-pull-request",
			"prepend",
			"prune-branches",
			"rename-branch",
			"repo",
			"ship",
			"sync",
		}
		for _, command := range commandsToAlias {
			if toggle {
				err := addAlias(command, prodRepo)
				if err != nil {
					cli.Exit(err)
				}
			} else {
				err := removeAlias(command, prodRepo)
				if err != nil {
					cli.Exit(err)
				}
			}
		}
	},
	Args: cobra.ExactArgs(1),
}

func addAlias(command string, repo *git.ProdRepo) error {
	result, err := repo.AddGitAlias(command)
	if err != nil {
		return fmt.Errorf("cannot create alias for %q: %w", command, err)
	}
	return repo.LoggingShell.PrintCommand(result.Command(), result.Args()...)
}

func removeAlias(command string, repo *git.ProdRepo) error {
	existingAlias := repo.GetGitAlias(command)
	if existingAlias == "town "+command {
		result, err := repo.RemoveGitAlias(command)
		if err != nil {
			return fmt.Errorf("cannot remove alias for %q: %w", command, err)
		}
		return repo.LoggingShell.PrintCommand(result.Command(), result.Args()...)
	}
	return nil
}

func init() {
	RootCmd.AddCommand(aliasCommand)
}
