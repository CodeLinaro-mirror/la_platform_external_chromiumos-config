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
