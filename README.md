# Project Setup for Partners

Note: There are two different types of configurations for partners. It is
important to know which type you are working with. One type of configuration
places the program and projects in separate repositories. The second type of
configuration places the program and projects in a single repository. This
difference results in slight differences in how you work with these types of
configurations and where you find key files and execute commands. The
instructions below attempt to make this distinction clear.

1. Before beginning verify that you have appropriate permissions to work with
   the project. This will usually mean having membership in the partner domain
   account that is configured for your project. Inquire with your local
   representative or Google contact if you need more information about the
   partner domain accounts configured for your project.
1. Follow the [Chromium OS Quick Start Guide](http://www.chromium.org/chromium-os/quick-start-guide)
   through to the end of the "Get the Source" section. This guide walks you
   through installing prerequisites and syncing the public Chromium OS source
   code into a $SOURCE_REPO directory. This step pulls down a lot of code and
   could take up to an hour.
1. Verify the name of your $PROGRAM and $PROJECT with your local representative
   or Google contact. These values will be used in the command below. For single
   repository configurations with projects directly in the program's
   subdirectories you will only get the $PROGRAM. Example commands for both
   separate repo and single repo variants will be shown below.
1. Run the following command to sync your $PROGRAM and $PROJECT from within your
   chromiumos checkout in the $SOURCE_REPO/src/config directory:

   ```
   # For separate $PROGRAM $PROJECT repo configurations:
   ./setup_project.sh $PROGRAM $PROJECT

   # For single $PROGRAM repo configurations:
   ./setup_project.sh $PROGRAM
   ```

   This command will execute a number of steps including checking out your
   program and project and other related repositories, symlinking a local
   manifest, and finally doing a full chromiumos sync.
1. The $SOURCE_REPO/src/config/bin directory contains utilties for working with
   your project. Add the directory to the end of your PATH. You will probably
   want to add this configuration in your ~/.bashrc file or other appropriate
   location so you don't have to repeatedly set the PATH:

   ```
   export PATH=$PATH:$SOURCE_REPO/src/config/bin
   ```

If you got to this point without an error you are set up to start working on
your project.

# Working with Projects for Partners

After setting up your project you'll want to note the location of several
important repositories within the checkout:

*   src/config: The repository that contains this README.md file. This repository
    contains the higher level framework including protocol buffer definitions,
    configuration language constructs, constraint checking code, and binaries
    for performing tasks.
*   src/program/$PROGRAM: The repository that defines the program of your
    project. This repository defines the constraints that your project follows.
*   src/project/$PROGRAM/$PROJECT: The repository that defines your project.
    This repository defines your project design under the constraints of the
    program it belongs to.

Partners will rarely propose changes to src/config and occasionally propose
changes to src/program/$PROGRAM. The bulk of a partner's work will occur in
in src/project/$PROGRAM/$PROJECT.

## Making Configuration Changes for your Project

Configuration changes are made to a project by adjusting the
[Starlark](https://docs.bazel.build/versions/master/skylark/language.html)
configuration definition in
$SOURCE_REPO/src/project/$PROGRAM/$PROJECT/config.star and then running the
gen_config script (added to the PATH above). An example session updating
project configuration follows:

```
# For separate $PROGRAM $PROJECT repo configurations:
cd $SOURCE_REPO/src/project/$PROGRAM/$PROJECT/
$EDITOR config.star
# Adjust contents of config.star and save.
gen_config config.star

# For single $PROGRAM repo configurations:
cd $SOURCE_REPO/src/program/$PROGRAM/${project subdir}
$EDITOR config.star
# Adjust contents of config.star and save.
gen_config config.star
```

For separate $PROGRAM $PROJECT repo configurations this will cause the
generation of payloads that can be found at:


*   $SOURCE_REPO/src/project/$PROGRAM/$PROJECT/generated/config.binaryproto
*   $SOURCE_REPO/src/project/$PROGRAM/$PROJECT/generated/config.cfg
*   $SOURCE_REPO/src/project/$PROGRAM/$PROJECT/generated/project/project-config.json

For single $PROGRAM repo configurations those payloads will be found at:

*   $SOURCE_REPO/src/program/$PROGRAM/${project subdir}/generated/config.binaryproto
*   $SOURCE_REPO/src/program/$PROGRAM/${project subdir}/generated/config.cfg
*   $SOURCE_REPO/src/program/$PROGRAM/${project subdir}/generated/project/project-config.json

Before uploading the changes for review you should check to see if your
changes pass constraint checks. You can do that by running the check_config
script from within your project's root directory:

```
# For separate $PROGRAM $PROJECT repo configurations:
cd $SOURCE_REPO/src/project/$PROGRAM/$PROJECT/
check_config

# For single $PROGRAM repo configurations:
cd $SOURCE_REPO/src/program/$PROGRAM/${project subdir}
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
[gerrit](https://chrome-internal-review.googlesource.com/). The exact URL will
for your CL will be output when the CL is uploaded. The CL will need to be
approved and pass CQ. Details on working with CLs and the progression through
review and CQ can be found in the
[Chromium OS Contributing Guide](https://chromium.googlesource.com/chromiumos/docs/+/master/contributing.md)
and more specifically in the
[Going through review](https://chromium.googlesource.com/chromiumos/docs/+/master/contributing.md#Going-through-review)
section. CQ verifies that you have correctly generated your configuration
payload and that you have not violated the program's constraints.
