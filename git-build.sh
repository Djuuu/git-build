#!/bin/sh

branches[0]=evo-bo-depot-primaire
branches[1]=bo-planif-anterieure
branches[2]=retards-partenaires
branches[3]=evo-bo-80
branches[4]=evos_bo_2015_03
branches[5]=bo-menu

############################################################################

destination=PREPROD
dest_remote=preprod

orig_remote=origin

merge_conflict_branch=".git/MERGE_CONFLICT_BRANCH"

############################################################################

# flags

skip_previous_branches=0
conflict_msg=""
conflict_branch=""

# "continue" mode
if [ "$1" == "--continue" ]; then
    skip_previous_branches=1
    conflict_msg=`cat .git/MERGE_MSG`
    conflict_branch=`cat $merge_conflict_branch`
fi


# Check repository state
if [ "$skip_previous_branches" == "0" ]; then
    if [ ! -z "$(git status --untracked-files=no --porcelain)" ]; then
        echo "Repository is not clean, exiting"
        exit 1
    fi
fi

# Check current checked out branch
current_branch=$(git symbolic-ref --short -q HEAD)
if [ "$current_branch" != "$destination" ]; then
    git checkout $destination
    git reset --hard origin/master
    echo
fi


# Merge
for i in "${branches[@]}"
do
    message="Merge branch '$i' into $destination"

    if [ "$skip_previous_branches" == "1" ]; then

        if [ "$conflict_branch" == "$i" ]; then
            # Commit (conflict resolution
            echo "$message  (conflict resolution)"

            git commit -m "$conflict_msg"

            skip_previous_branches=0
            rm -f $merge_conflict_branch
            echo
        else
            # Slpi (already merged)
            echo "skipping branch $i"
            echo
        fi
    else
        # Merge
        echo "$message"

        git merge origin/$i -m "$message"

        if [ $? -ne 0 ]; then
            echo $i > $merge_conflict_branch
            exit 1;
        fi

        echo
    fi
done

echo
echo "Merge OK. You can probably do : "
echo
echo "  git push $orig_remote       :$destination"
echo "  git push $dest_remote       :$destination"
echo
echo "  git push $orig_remote        $destination"
echo

