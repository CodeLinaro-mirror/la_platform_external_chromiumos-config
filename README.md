# Project Setup for Partners

1. Before beginning verify that you have appropriate permissions to work with
   the project. This will usually mean having membership in the partner domain
   account that is configured for your project. Inquire with your local
   representative or Google contact if you need more information about the
   partner domain accounts configured for your project.
1. Follow the [Chromium OS Quick Start Guide](http://www.chromium.org/chromium-os/quick-start-guide)
   through to the end of the "Get the Source" section. This guide walks you
   through installing prerequisites and syncing the public Chromium OS source
   code.
1. Verify the name of your $PROGRAM and $PROJECT with your local representative
   or Google contact. These values will be used in the command below.
1. Run the following command to sync your $PROGRAM and $PROJECT from within your
   chromiumos checkout:

   ```
   setup_project.sh $PROGRAM $PROJECT
   ```

   This command will execute a number of steps including checking out your
   project, symlinking a local manifest, and finally doing a full chromiumos
   sync.

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
