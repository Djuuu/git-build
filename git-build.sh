#!/bin/sh

############################################################################
# flags, vars

continue=0
current_branch=
current_build=

origin_remote=origin
starting_point=master

git_build_current_branch_file=".git/GIT_BUILD_CURRENT_BRANCH"
git_build_current_build_file=".git/GIT_BUILD_CURRENT_BUILD"

############################################################################
# functions

usage()
{
    echo
    cat << EOF
usage: $0 [<build-name>|--continue]
EOF
    echo
}

load_remote_conf()
{
    if [ -z $current_build ]; then
        echo "Git Build - No remote specified"
        usage
        exit 1;
    fi

    local remote_conf_file="./.gitbuild-${current_build}"

    if [ ! -f $remote_conf_file ]; then
        echo "Git Build - Config file $remote_conf_file not found"
        exit 1
    fi

    source $remote_conf_file

    if [ -z $build_branches ]; then
        echo "Git Build - build_branches is empty. Check $remote_conf_file conf"
        exit 2
    fi

    if [ -z $build_branch ]; then
        echo "Git Build - build_branch is empty. Check $remote_conf_file conf"
        exit 2
    fi

    echo "Git Build - branch to build   : $build_branch"
    echo "Git Build - branches to merge : "
    for i in "${build_branches[@]}"
    do
        echo "   - $i"
    done
    echo
}

init_normal()
{
    echo "Git Build - Init new build"
    echo

    # Check repository state
    if [ ! -z "$(git status --untracked-files=no --porcelain)" ]; then
        echo "Repository is not clean, exiting"
        exit 1
    fi

    current_build=$1
}

init_continue()
{
    echo "Git Build - Continue previous build"
    echo

    continue=1

    # Check / get cached configuration

    local running=
    if [ ! -f $git_build_current_branch_file ]; then
        running=1
    fi
    if [ ! -f $git_build_current_build_file ]; then
        running=1
    fi

    if [ ! -z $running ]; then
        echo "Git Build - No build seems to be running"
        usage
        exit 2;
    fi

    current_branch=`cat $git_build_current_branch_file`
    current_build=`cat $git_build_current_build_file`
}

dump_current_build()
{
    echo $i            > $git_build_current_branch_file
    echo $current_build > $git_build_current_build_file
}

clean_current_build()
{
    rm -f $git_build_current_branch_file
    rm -f $git_build_current_build_file
}

init()
{
    if [ ! -d ".git" ]; then
        echo "Git Build - Not a Git repository"
        exit 1
    fi

    if [ "$1" == "--continue" ]; then
        init_continue
    else
        init_normal $1
    fi

    load_remote_conf
}

############################################################################
# script


init $1


if [ "$continue" != "1" ]; then
    # Check current checked out branch
    current_branch=$(git symbolic-ref --short -q HEAD)
    if [ "$current_branch" != "$build_branch" ]; then
        echo "Git Build - Current branch : $current_branch ; Checking out $build_branch"
        git checkout -f $build_branch
        echo
    fi

    echo "Git Build - resetting to master"
    git reset --hard $starting_point
    echo
fi


# Merge
for i in "${build_branches[@]}"
do
    message="Merge branch '$i' into $build_branch"

    if [ "$continue" == "1" ]; then

        if [ "$current_branch" == "$i" ]; then
            # Commit (conflict resolution
            echo "Git Build - $message  (conflict resolution)"

            git commit -m "$(cat .git/MERGE_MSG)"

            if [ $? -ne 0 ]; then
                dump_current_build
                exit 1;
            fi

            continue=0
            clean_current_build
            echo
        else
            # Skip (already merged)
            echo "Git Build - skipping branch $i"
            echo
        fi
    else
        # Merge
        echo "Git Build - $message"

        git merge $origin_remote/$i -m "$message"

        if [ $? -ne 0 ]; then
            dump_current_build
            exit 1;
        fi

        echo
    fi
done

echo
echo "Git Build - Merge OK. You can probably do : "
echo
echo "  git push $origin_remote :$build_branch"
echo "  git push $current_build :$build_branch"
echo
echo "  git push $origin_remote $build_branch"
echo
