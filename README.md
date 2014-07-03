talk-repo-splitter
===========================

Contains a ruby script which:

* expects a git repository as source and a target location
* creates new git repositories at target location for every directory (module)
in the source repository transferring the (individual) history including tags
* creates a new repository at target location with all containing repos added as
git submodules

##Preparation
The script currently needs to be modified to define:
* which directories of the source repository to export
* which remote url each new repository should have

The definitions are done in the 'modules' array.

##Execution
The script can be executed as follows:

```bash
ruby script.rb <source_repository> <target_location>
```
The execution time can be (hours) long depending on the number of directories
defined as well as branches and tags in the source repository. The script works
as follows:

1. Read all remote branches and tags from source repository.
2. Create a new git repository at target location (parent repository).
3. For each module:
  1. Create a new repository in a new subfolder of target location.
  2. For each branch:
    1. Retrieve the latest commit of the branch.
    2. Create a new subtree of the commit in the source repository for the given
       module. This traverses the entire history.
    3. Pull the subtree into the new repository.
    4. Remove the subtree from the source repository.
  3. For each tag:
    1. Retrieve the commit of the tag.
    2. Create a new subtree of the commit in the source repository for the given
       module.
    3. Pull the subtree into the new repository.
    4. Remove the subtree from the source repository.
  4. Checkout the 'master' branch in the new repository.
  5. Add the defined remote url to the new repository.
  6. Add the new repository as submodule of the parent repository.
4. Commit all submodules to the parent repository on 'master'.
5. For each branch (except 'master'):
  1. For each module:
    1. Checkout the branch in the module repository.
  2. Create the branch in the parent repository and checkout.
  3. Commit all submodules to the parent repository.
6. Done
