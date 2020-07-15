# ChromeOS Project Configuration

[TOC]

## Overview

This repo contains schema definitions and utilities for configuring ChromeOS
hardware and software. Other repos will use this repo to generate config
payloads to drive ChromeOS builds, manufacturing, etc.

The config payloads are [Protocol Buffers](https://developers.google.com/protocol-buffers)
which are generated via [Starlark](https://docs.bazel.build/versions/master/skylark/language.html).
A basic understanding of protobuf and Starlark is required to manage these
configs.

## Project Setup for Partners

### Syncing Private Repos

**Googlers should have the project and program config repos as part of the
internal-manifest checkout and should not run these steps.**

Partners will do a public checkout and then add
config repos for the projects and programs they are working on.

1. Before beginning verify that you have appropriate permissions to work with
   the project. This will usually mean having membership in the partner domain
   account that is configured for your project. Inquire with your local
   representative or Google contact if you need more information about the
   partner domain accounts configured for your project.
1. Follow the [Chromium OS Quick Start Guide](http://www.chromium.org/chromium-os/quick-start-guide)
   through to the end of the "Get the Source" section. This guide walks you
   through installing prerequisites and syncing the public Chromium OS source
   code into a `$SOURCE_REPO` directory. This step pulls down a lot of code and
   could take up to an hour.
1. Verify the name of your `$PROGRAM` and `$PROJECT` with your local representative
   or Google contact.

1. Run the following command to sync your `$PROGRAM` and `$PROJECT` from within your
   chromiumos checkout in the `$SOURCE_REPO/src/config` directory:

   ```
   ./setup_project.sh $PROGRAM $PROJECT
   ```

   This command will execute a number of steps including checking out your
   program and project and other related repositories, symlinking a local
   manifest, and finally doing a full chromiumos sync.

### Configuring the Chroot

**As of 6/8/2020, profiles have not been set up for all projects. Please check with your Google representative on the status of your project.**

Portage profiles are used to build ChromeOS with configuration from a single
project repo. The profile can be set with `setup_board`:

```
(cr) $ setup_board --board=$PROGRAM --profile=$PROJECT
```

After the profile is set, `build_packages` can be called normally:

```
(cr)  ~/trunk/src/scripts $ ./build_packages --board=$PROGRAM
```

Note that if no profile is set, the default `base` profile will use
configuration from all projects in the program.

#### Notes

- The above profiles work by setting Portage `USE` flags which affect the
`CROS_WORKON_PROJECT`s that are chosen. Any subset of projects can be chosen
with these `USE` flags, e.g.

```
(cr) $ USE="project_a project_b" emerge ...
```

- The `project_all` `USE` flag is a convenience to use all projects.

If you got to this point without an error you are set up to start working on
your project.

## Adding Utilities to Your `PATH`

The `$SOURCE_REPO/src/config/bin` directory contains utilties for working with
your project. Add the directory to the end of your `PATH`. You will probably
want to add this configuration in your `~/.bashrc` file or other appropriate
location so you don't have to repeatedly set the `PATH`:

```
export PATH=$PATH:$SOURCE_REPO/src/config/bin
```

## Working with Projects for Partners

After setting up your project you'll want to note the location of several
important repositories within the checkout:

*   `src/config`: The repository that contains this README.md file. This repository
    contains the higher level framework including protocol buffer definitions,
    configuration language constructs, constraint checking code, and binaries
    for performing tasks.
*   `src/program/$PROGRAM`: The repository that defines the program of your
    project. This repository defines the constraints that your project follows
    and config constructs that are shared across projects in the program.
*   `src/project/$PROGRAM/$PROJECT`: The repository that defines your project.
    This repository defines your project design under the constraints of the
    program it belongs to.

Partners will rarely propose changes to `src/config` and occasionally propose
changes to `src/program/$PROGRAM`. The bulk of a partner's work will occur in
in `src/project/$PROGRAM/$PROJECT`.

## Making Configuration Changes for your Project

Configuration changes are made to a project by adjusting the
[Starlark](https://docs.bazel.build/versions/master/skylark/language.html)
configuration definition in
`$SOURCE_REPO/src/project/$PROGRAM/$PROJECT/config.star` and then running the
`gen_config` script (added to the `PATH` above). An example session updating
project configuration follows:

```
cd $SOURCE_REPO/src/project/$PROGRAM/$PROJECT/
$EDITOR config.star
# Adjust contents of config.star and save.
gen_config config.star
```

Note that many `config.star` files are executable, with the shebang
`#!/usr/bin/env gen_config`. Thus `./config.star` can be used as a shortcut for
`gen_config config.star` if `gen_config` is on `PATH`.

This will cause the generation of payloads and config files that can be found
at:

*   `$SOURCE_REPO/src/project/$PROGRAM/$PROJECT/generated/config.jsonproto`
*   `$SOURCE_REPO/src/project/$PROGRAM/$PROJECT/generated/project/sw_build_config/platform/chromeos-config/generated/project-config.json`

`config.jsonproto` is a file containing the config protobuf
[encoded as JSON](https://developers.google.com/protocol-buffers/docs/proto3#json).

`project-config.json` is the config in the [legacy YAML schema](https://chromium.git.corp.google.com/chromiumos/platform2/+/refs/heads/master/chromeos-config/README.md#Config-Schema)
and is present for backwards-compatibility.

Before uploading the changes for review you should check to see if your
changes pass constraint checks. You can do that by running the `check_config`
script from within your project's root directory:

```
cd $SOURCE_REPO/src/project/$PROGRAM/$PROJECT/
check_config
```

If your changes pass the contraint checks you are ready to submit your
CL. To submit the changes the user first commits the files and then submits
them to commit queue (CQ):

```
git add .
git commit
# Add commit message with BUG= and TEST= directives
repo upload .
```

This will result in a reviewable CL in
[gerrit](https://chrome-internal-review.googlesource.com/). The exact URL
for your CL will be output when the CL is uploaded. The CL will need to be
approved and pass CQ. Details on working with CLs and the progression through
review and CQ can be found in the
[Chromium OS Contributing Guide](https://chromium.googlesource.com/chromiumos/docs/+/master/contributing.md)
and more specifically in the
[Going through review](https://chromium.googlesource.com/chromiumos/docs/+/master/contributing.md#Going-through-review)
section. CQ verifies that you have correctly generated your configuration
payload and that you have not violated the program's constraints.

### CQ Verifier Access for Partners

Some CQ verifiers will be visible to partners, for example the verifiers of the
project and program configs. Visible builds will appear as links on the Gerrit
page for your CL. The builds are displayed with [Milo](https://g3doc.corp.google.com/company/teams/chrome/ops/luci/milo.md?cl=head) (LUCI's UI).

**Note on stdout log access**: [LogDog](https://g3doc.corp.google.com/company/teams/chrome/ops/luci/logdog/index.md?cl=head) (LUCI's logging service)
currently doesn't support partner access. Thus, stdout logs for key steps of the
build are mirrored to per-project Google Storage buckets. The Google Storage
mirrored logs appear as links like "stdout (GS mirror)" on the Milo page.

## Constraint Checkers

As described above, a project config is verified against the constraints of the
program before it is submitted. This is done by `check_config` locally and by
CQ builders before submission.

Constraints look and behave similar to Python unit tests, but are passed a
program and project `ConfigBundle` to do assertions on. Constraints that apply
to all programs and projects are in the [payload_utils/checker/common_checks](https://chromium.googlesource.com/chromiumos/config/+/refs/heads/master/payload_utils/checker/common_checks/) directory. Constraints can also be program-specific; these
constraints are under the `checks` directory of the program repo. For example,
see the [Galaxy](https://chrome-internal.googlesource.com/chromeos/program/galaxy/+/refs/heads/master/checks/)
test data program.

## Directory Structure

### chromiumos/config

For contributing configuration changes for programs and projects, a familiarity
with the follow directories in this repo is helpful:

- `proto/`: Protobuf definitions for hardware configuration,
software configuration, etc. This serves as the main API for configuring your
project and program.

- `util/`: Starlark utilities for use in program and project repos. Some
utility functions are basic wrappers around Protobuf construction, others help
with patterns that are common across patterns, e.g. configuring firmware
payloads.

- `test/`: A fake program and project. Useful to demonstrate the use of the
Starlark utilities.

- `bin/`: Tools needed to work in the configuration ecosystem, see the [above
section](#Adding-Utilities-to-Your) on adding these tools to your `PATH`.

- `go/`: Golang proto bindings. Used by platform code.

- `python/`: Python proto bindings. Used by platform code.

The following directories are likely more useful for contributors to the
configuration and infrastructure systems:

- `infra/`, `recipes/`: Needed to roll proto definitions into
[Recipes](https://chromium.googlesource.com/infra/luci/recipes-py) repos.

- `payload_utils/`: Utilities for working on configuration payloads, e.g. CQ
checker to validate project configs.

- `presubmit/`: Common files and libraries for program and project repo
presubmits.

- `sbin/`:  Tools admins use to create and manage programs and projects.
Regular users should not need to use these tools.

### Program and Project Repos

For contributing configuration changes for programs and projects, a familiarity
with their layout patterns is helpful.

- `config.star`: The main Starlark file to generate a program or project's
configuration payload. See
[Making Configuration Changes for your Project](#Making-Configuration-Changes-for-your-Project)

- `generated/`: Generated configuration payloads.

- `sw_build_config/`: Files for configuring software on the project's build.
Contains manually-edited and generated files.

- `local_manifest.xml`: Local manifest for working on the project. See
[Project Setup for Partners](#Project-Setup-for-Partners)

- `config/`: Symlink to the `chromiumos/config` repo, for importing Starlark
utils.

- `program/`: Symlink from a project repo to the corresponding program repo, for
importing program-level Starlark functions.

- `PRESUBMIT.py`, `PRESUBMIT.cfg`: Presubmit configuration files. Shared across
all programs and projects via symlink.

## Making Bulk Changes Across Repos

Program and project config are spread across repos, so changes and refactors
often span multiple repos. A very common pattern occurs when a change in a
program repo causes changes in that program's project repos when running
`gen_config` for the projects. Tooling is available to make such changes more
automated and less tedious than handcrafting individual CLs. Specifically, using
the ClFactory tool and familiarity with `repo forall` and the
`chromite/bin/gerrit` tools is helpful for these changes.

### ClFactory

[ClFactory](https://chromium.googlesource.com/chromiumos/infra/recipes/+/HEAD/recipes/cl_factory.py)
is a builder that can generate CLs that are the fallout from changes
via other CLs. ClFactory was written to address the pattern mentioned above
where a change at the chromiumos/config or chromeos/program/$PROGRAM level
results in changes in a high number of dependent repos. In order to remain
consistent and pass CQ these typically must be submitted together. Generating
these changes locally, setting commit messages, wiring up Cq-Depends, and
sending out for review can be tedious, error prone, and time consuming.
ClFactory is intended to make such CLs for you.

With ClFactory you write your input CLs as normal. Then, to generate the
dependent CLs that that result from the changes, you invoke a builder that
takes care of the rest. It will checkout the source, apply your input CLs,
run `gen_config` in the dependent projects, create the CLs, add reviewers,
etc..

A wrapper script,
[cl_factory](https://chromium.googlesource.com/chromiumos/config/+/HEAD/bin/cl_factory),
that lives in the bin directory of this repo, has been provided to simplify
invoking ClFactory. The arguments are a bit involved, but the wrapper makes it
much simpler than crafting a `bb add` command directly, which is the command
that the wrapper delegates to. A typical invocation of ClFactory would look
something like this:

```
./bin/cl_factory \
  --cl https://chrome-internal-review.googlesource.com/c/chromeos/program/galaxy/+/3095418 \
  --regex src/program src/project \
  --reviewers reviewer1@chromium.org reviewer2@google.com \
  --ccs author@google.com \
  --hashtag regen-audio-configs \
  --message "Regenerate audio configs per changes at program level.

BUG=chromium:1092954
TEST=CQ"
```

This would take CL 3095418 as input and run `gen_config` in the projects that
match per the regex arguments. The resultant CLs would have reviewers, CCs, and
other attributes set as indicated. When the builder is launched `cl_factory`
will output a link to the milo page for that build. A link to this same build
will also appear in the commit message of the generated CLs. From that milo
build page you can follow the progress of generating the dependant CLs. The milo
page also provides some valuable information in the step output. In particular,
the "summarize results" step contains two pieces of information that will be of
interest to the CL author and the reviewers. The first piece is the "unified
diff" output. This will allow authors and reviewers to see what the entirety of
all the changes are without having to open each individual generated CL. The
second piece is the "gerrit commands." This output lists commands that can be
used to label verified, label reviewed, and label for commit queue in bulk from
the command line. This allows users to do this quickly as opposed to tediously
navigating the gerrit pages of the generated CLs.

### `repo forall` and `chromite/bin/gerrit` tooling

`repo forall` can be used to make many commits across repos:

```
# Begin branch in all projects.
repo start --all fixbuggyvalue

# Find all config.star files and fix bug.
find src/project -name config.star -exec sed -i 's/buggyvalue/goodvalue/' {} \;

# Make a commit for all project repos.
repo forall -r src/project -c 'git commit -a -m"
$(basename $REPO_PROJECT): Fix buggyvalue.

BUG=chromium:123
TEST=...
"'

# Upload changes with hashtag "fixbuggyvalue"
repo upload --ht=fixbuggyvalue --re=reviewer@google.com
```

Similarly, the `gerrit` tool can apply a label to many CLs:

```
gerrit label-cq `gerrit --raw search "owner:me hashtag:fixbuggyvalue"` 1
```

For anything where gerrit cannot accept multiple CLs, a shell loop
can be used, for example the reviewers command:

```
for cl in `gerrit -i --raw search "owner:me status:open hashtag:fixit"`; do
  gerrit reviewers $cl reviewer1@google.com reviewer2@google.com
done
```
