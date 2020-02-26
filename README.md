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
1. Do a one off clone of your project into the source tree:

   ```shell
   git clone https://chrome-internal.googlesource.com/chromeos/project/$program/$project src/project/$program/$project
   ```

1. Make a symlink to include your local manifest:

   ```shell
   mkdir -p .repo/local_manifests
   ln -sr src/project/$program/$project/local_manifest.xml .repo/local_manifests/$project.xml
   ```

1. Do a one time force sync to get the repo up to date with the newly included
   local manifest:

   ```shell
   repo sync --force-sync -j48
   ```
