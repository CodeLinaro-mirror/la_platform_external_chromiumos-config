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
   ./setup_project.sh --program=$PROGRAM --project=$PROJECT
   ```

   This command will execute a number of steps including checking out your
   program and project and other related repositories, symlinking a local
   manifest, and finally doing a full chromiumos sync.

### Syncing to a specific ChromeOS version (buildspec)

**Googlers have access to full private buildspecs and should not run these
steps.**

Partners only have access to public buildspecs, which do not include information
about private partner-specific projects. Infrastructure now exists to create
a project-specific buildspec from a local_manifest.xml file. The following
workflow explains how to include said project-specific buildspecs in a public
ChromeOS checkout, so that partners can properly sync to a specific ChromeOS
version.

1. Make sure that you and your project(s) are enrolled in this program (a
   Google contact will need to set this up for you.)
1. Choose the buildspec you'd like to sync to, e.g. `full/buildspecs/92/13963.2.0.xml`. You can list available buildspecs by running `gsutil ls -R gs://chromiumos-manifest-versions/`.
    1. [Instructions for setting up `gsutil`](https://cloud.google.com/storage/docs/gsutil_install)
    1. Provided the project in question has been enrolled by your Googler contact, project-specific buildspecs are automatically created for enrolled projects for new build versions (at up to a 12 hour delay). If you'd like to sync to an older buildspec (or one that has not yet been created):
        1. run ```bb add chromeos/partner-access/project-buildspec -p 'projects=["{your project}/{your program}"]' -p buildspec={your buildspec}```, e.g. ```bb add chromeos/partner-access/project-buildspec -p 'projects=["brya/brya"]' -p buildspec=buildspecs/96/14268.0.0.xml```.
        1. Follow the link that `bb add` prints and verify that the run has successfully completed.
1. Run the following commands:
    1. `export BUILDSPEC={your buildspec}`, e.g. `export BUILDSPEC=buildspecs/92/13963.2.0.xml`.
    1. `export PROJECT={your project}`, e.g. `export PROJECT=galaxy`.
    1. `export PROGRAM={your program}`, e.g. `export PROGRAM=milkyway`.
    1. `export CHECKOUT={path to your checkout}`, e.g. `export CHECKOUT=~/my_checkout`.
    1. ```(mkdir -p $CHECKOUT && cd $CHECKOUT && repo init -u gs://chromiumos-manifest-versions/$BUILDSPEC --standalone-manifest)```
    1. ```./setup_project.sh --checkout=$CHECKOUT --program=$PROGRAM --project=$PROJECT --buildspec=$BUILDSPEC```
        1. If you do not already have `setup_project.sh` available in an existing ChromeOS checkout, you can download it [here](https://chromium.googlesource.com/chromiumos/config/+/refs/heads/main/setup_project.sh).
    1. ```cd $CHECKOUT && repo sync --force-sync -j12 --nmu``` (`--nmu` is a temporary workaround to a known bug, this will be resolved shortly.)

Run `./setup_project.sh -h` for a full list of options/arguments, e.g. `--chipset`, `--all_projects`, and `--other-repos`.

#### Googler Workflows:

1. Enrolling a new partner:
    1. (Temporary, as of 08/26/21): The setup_project app has not yet been verified. Add users as Test Users on the setup_project OAuth configuration page [screenshot](https://screenshot.googleplex.com/A4g7m4gaUeYB2Di).
    1. In order for a partner to kick off a project-buildspec build via bb add, they need to be added to [cria/project-chromeos-partner-access](https://chrome-infra-auth.appspot.com/auth/groups/project-chromeos-partner-access). If you want to add a google or mdb group, you need to export the group to CRIA by cutting a CL ([example](https://critique-ng.corp.google.com/cl/386477578)).
1. Enrolling a new project:
    1. Enroll the appropriate projects in automatic buildspec creation by adding them to the `project_buildspecs` property of `manifest-doctor` ([example](crrev.com/i/4081090)).
    1. (Temporary, as of 08/26/21): Create a program bucket: From the root of a chromiumos checkout, run ```./src/config/sbin/create_partner_repo --run createprogrambuckets --program {your program}```.
        1. For now, you need to manually set the "Storage Object Viewer" permission for the appropriate groups ([example](https://screenshot.googleplex.com/63ioviutNRiebL2)).

#### See Also
* [go/per-project-buildspecs](http://go/per-project-buildspecs)
* [go/cros-partner-buildspec-sync](http://go/cros-partner-buildspec-sync)

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

`project-config.json` is the config in the [legacy YAML schema](https://chromium.git.corp.google.com/chromiumos/platform2/+/HEAD/chromeos-config/README.md#Config-Schema)
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
[Chromium OS Contributing Guide](https://chromium.googlesource.com/chromiumos/docs/+/HEAD/contributing.md)
and more specifically in the
[Going through review](https://chromium.googlesource.com/chromiumos/docs/+/HEAD/contributing.md#Going-through-review)
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

## Contributing Protocol Buffer Schema Changes

Protobuf schemas live under the `config` directory. To make a schema change
(e.g. add a field), edit the `.proto` file and then run the `generate.sh` script
in the root of this repo to generate the Protobuf bindings.

See the [proto3 Language Guide](https://developers.google.com/protocol-buffers/docs/proto3)
for more background on Protobuf.

## Constraint Checkers

As described above, a project config is verified against the constraints of the
program before it is submitted. This is done by `check_config` locally and by
CQ builders before submission.

Constraints look and behave similar to Python unit tests, but are passed a
program and project `ConfigBundle` to do assertions on. Constraints that apply
to all programs and projects are in the [payload_utils/checker/common_checks](https://chromium.googlesource.com/chromiumos/config/+/HEAD/payload_utils/checker/common_checks/) directory. Constraints can also be program-specific; these
constraints are under the `checks` directory of the program repo. For example,
see the [Galaxy](https://chrome-internal.googlesource.com/chromeos/program/galaxy/+/HEAD/checks/)
test data program.

## Public Configs

The private project repo contains the entire project config; some config fields
must remain private and some can be made public for building from a public
checkout. Fields are private by default, and can be made public via the
[`chromiumos.config.public_replication.PublicReplication`](https://chromium.googlesource.com/chromiumos/config/+/HEAD/proto/chromiumos/config/public_replication/public_replication.proto)
message (see the message comment for the most up to date documentation).

The `gen_config` command will parse `PublicReplication` messages to generate
`public_config.jsonproto` and `public_sw_build_config` outputs, which are
filtered versions of the full `config.jsonproto` and `sw_build_config` outputs,
respectively. These public outputs will be automatically copied to the public
[`chromiumos/project`](https://chromium.googlesource.com/chromiumos/project/+/refs/heads/main)
repo after CLs are submitted, where they can be used in public ebuilds (because
the file structure of the public configs is symmetrical to the private configs,
the ebuild structure can be similar to private ebuilds).

As with other configuration, Starlark functions in `util/` will provide defaults
for public fields, but these settings can be overridden by individual programs
and projects.

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

- `public_sw_build_config/`: A filtered version of `sw_build_config`, for use
in public builds.

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
dependent CLs that result from the changes, you invoke a builder that takes care
of the rest. It will checkout the source, apply your input CLs, run `gen_config`
in the dependent projects, create the CLs, add reviewers, etc..

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

# DUT Attributes
The `starlark/dut_attributes` directory defines a `DutAttributesList` containing
all `DutAttributes` valid for use in test plans. New `DutAttributes` can be
added in this file.

Note that a **`DutAttribute` used on any branch cannot be deleted or modified**,
because this may break the test plan on the branch.
