
# git-build

This script merges a list of branch into a defined destination branch, starting from `master`.

It can be used to build a new *release candidate* composed of several branches, with a clean git tree.

## Installation

* Clone The repository

Then : 
* Create a symlink to the script in a directory in your path
```bash
ln -s /path/to/KC-git-build/git-build.sh ~/bin/git-build
```

OR

* Create a git alias in your `.gitconfig`
```ini
[alias]
    build = "!bash /path/to/KC-git-build/git-build.sh
```

## Usage

### Build Configuration
 
Create a config file named `.gitbuild-<BUILDNAME>` in your project. 

eg: `.gitbuild-preprod`

The file shoud contain the following : 

```bash
# Name of the branch to build
build_branch=PREPROD

# Branches to merge into $build_branch
build_branches[0]=some-branch-name
build_branches[1]=other-branch-name
build_branches[2]=branch-name-3
# ...
```

### Launching a build

```bash
git build <BUILDNAME>
```

e.g. `git build preprod`

Conflicts should be resolved the same way than when rebasing : 
 * resolve conflicts
 * stage the fixed files
 * run `git build --continue`
