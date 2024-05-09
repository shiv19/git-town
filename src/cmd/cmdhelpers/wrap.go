package cmdhelpers

import (
	"github.com/git-town/git-town/v14/src/git/gitdomain"
	. "github.com/git-town/git-town/v14/src/gohacks/prelude"
	"github.com/git-town/git-town/v14/src/vm/opcodes"
	"github.com/git-town/git-town/v14/src/vm/program"
)

// Wrap makes the given program perform housekeeping before and after it executes.
func Wrap(program *program.Program, options WrapOptions) {
	if program.IsEmpty() {
		return
	}
	if !options.DryRun {
		program.Add(&opcodes.PreserveCheckoutHistory{
			PreviousBranch: options.PreviousBranch,
		})
	}
	if options.StashOpenChanges {
		program.Prepend(&opcodes.StashOpenChanges{})
		program.Add(&opcodes.RestoreOpenChanges{})
	}
}

// WrapOptions represents the options given to Wrap.
type WrapOptions struct {
	DryRun           bool
	PreviousBranch   Option[gitdomain.LocalBranchName]
	RunInGitRoot     bool
	StashOpenChanges bool
}
