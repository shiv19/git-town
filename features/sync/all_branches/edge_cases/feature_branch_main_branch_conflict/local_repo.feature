Feature: handle merge conflicts between feature branch and main branch in a local repo

  Background:
    Given my repo does not have a remote origin
    And my repo has the local feature branches "alpha", "beta", and "gamma"
    And my repo contains the commits
      | BRANCH | LOCATION | MESSAGE      | FILE NAME        | FILE CONTENT  |
      | main   | local    | main commit  | conflicting_file | main content  |
      | alpha  | local    | alpha commit | feature1_file    | alpha content |
      | beta   | local    | beta commit  | conflicting_file | beta content  |
      | gamma  | local    | gamma commit | feature3_file    | gamma content |
    And I am on the "main" branch
    And my workspace has an uncommitted file
    When I run "git-town sync --all"

  Scenario: result
    Then it runs the commands
      | BRANCH | COMMAND                  |
      | main   | git add -A               |
      |        | git stash                |
      |        | git checkout alpha       |
      | alpha  | git merge --no-edit main |
      |        | git checkout beta        |
      | beta   | git merge --no-edit main |
    And it prints the error:
      """
      To abort, run "git-town abort".
      To continue after having resolved conflicts, run "git-town continue".
      To continue by skipping the current branch, run "git-town skip".
      """
    And I am now on the "beta" branch
    And my uncommitted file is stashed
    And my repo now has a merge in progress

  Scenario: abort
    When I run "git-town abort"
    Then it runs the commands
      | BRANCH | COMMAND                                   |
      | beta   | git merge --abort                         |
      |        | git checkout alpha                        |
      | alpha  | git reset --hard {{ sha 'alpha commit' }} |
      |        | git checkout main                         |
      | main   | git stash pop                             |
    And I am now on the "main" branch
    And my workspace has the uncommitted file again
    And my repo is left with my original commits
    And there is no merge in progress

  Scenario: skip
    When I run "git-town skip"
    Then it runs the commands
      | BRANCH | COMMAND                  |
      | beta   | git merge --abort        |
      |        | git checkout gamma       |
      | gamma  | git merge --no-edit main |
      |        | git checkout main        |
      | main   | git stash pop            |
    And I am now on the "main" branch
    And my workspace has the uncommitted file again
    And there is no merge in progress
    And my repo now has the commits
      | BRANCH | LOCATION | MESSAGE                        |
      | main   | local    | main commit                    |
      | alpha  | local    | alpha commit                   |
      |        |          | main commit                    |
      |        |          | Merge branch 'main' into alpha |
      | beta   | local    | beta commit                    |
      | gamma  | local    | gamma commit                   |
      |        |          | main commit                    |
      |        |          | Merge branch 'main' into gamma |
    And my repo now has these committed files
      | BRANCH | NAME             | CONTENT       |
      | main   | conflicting_file | main content  |
      | alpha  | conflicting_file | main content  |
      |        | feature1_file    | alpha content |
      | beta   | conflicting_file | beta content  |
      | gamma  | conflicting_file | main content  |
      |        | feature3_file    | gamma content |

  Scenario: continue without resolving the conflicts
    When I run "git-town continue"
    Then it runs no commands
    And it prints the error:
      """
      you must resolve the conflicts before continuing
      """
    And I am still on the "beta" branch
    And my uncommitted file is stashed
    And my repo still has a merge in progress

  Scenario: continue after resolving the conflicts
    When I resolve the conflict in "conflicting_file"
    And I run "git-town continue"
    Then it runs the commands
      | BRANCH | COMMAND                  |
      | beta   | git commit --no-edit     |
      |        | git checkout gamma       |
      | gamma  | git merge --no-edit main |
      |        | git checkout main        |
      | main   | git stash pop            |
    And all branches are now synchronized
    And I am now on the "main" branch
    And my workspace has the uncommitted file again
    And there is no merge in progress
    And my repo now has these committed files
      | BRANCH | NAME             | CONTENT          |
      | main   | conflicting_file | main content     |
      | alpha  | conflicting_file | main content     |
      |        | feature1_file    | alpha content    |
      | beta   | conflicting_file | resolved content |
      | gamma  | conflicting_file | main content     |
      |        | feature3_file    | gamma content    |

  Scenario: continue after resolving the conflicts and committing
    When I resolve the conflict in "conflicting_file"
    And I run "git commit --no-edit"
    And I run "git-town continue"
    Then it runs the commands
      | BRANCH | COMMAND                  |
      | beta   | git checkout gamma       |
      | gamma  | git merge --no-edit main |
      |        | git checkout main        |
      | main   | git stash pop            |
