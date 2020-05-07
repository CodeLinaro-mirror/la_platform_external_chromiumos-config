# ChromeOS Project Admin Tools

This directory contains tools used by admin users to create and manage
programs and projects. Regular users should not need to use these tools.

The tools in this directory include:

*   `create_partner_repo`: This script does the heavy lifting in creating
    new programs and projects. It creates the repos, sets ACLs, makes
    necessary manifest changes, etc.
*   `create_project_buckets`: This script creates and sets the ACLs on
    Google Storage buckets that partners have access to for examining
    build artifacts. Currently this is used to give partners access to
    build logs.
*   `gen_project`: This script puts the basic skeleton of files and symlinks
    in place when starting a new program and project. It is intended to
    bootstrap the process and lay things out in an idiomatic way.
