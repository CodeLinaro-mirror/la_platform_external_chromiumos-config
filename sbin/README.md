# ChromeOS Project Admin Tools

This directory contains tools used by admin users to create and manage
programs and projects. Regular users should not need to use these tools.

The tools in this directory include (described in more detail below):

*   `create_partner_repo`: This script does the heavy lifting in creating
    new programs and projects. It creates the repos, sets ACLs, makes
    necessary manifest changes, etc.
*   `gen_project`: This script puts the basic skeleton of files and symlinks
    in place when starting a new program and project. It is intended to
    bootstrap the process and lay things out in an idiomatic way.

## `create_partner_repo`

The script creates partner program or project git repos, gerrit groups, and
applies ACLs to both the repos and groups. The script is idempotent and can be
re-run as many times as you wish:

*   The
    [Gerrit Rest](https://gerrit-review.googlesource.com/Documentation/rest-api.html)
    and
    [gob-ctl](https://g3doc.corp.google.com/company/teams/gerritcodereview/users/gob-ctl.md#create-a-git-repository)
    apis check if repo and gerrit groups exist.
*   ACLs can be re-applied without any side affects.
*   Creation of local_manifest step will be skipped if one already exists.
*   Creation and ACL setting on already existing gs buckets is a noop.

### Requirements :

1.  The script runner needs to be added to group
    [mdb/chrome-git-admins](https://ganpati.corp.google.com/chrome-git-admins).
    Request to be added should go to
    [mdb/chrome-git-admins-ninja](https://ganpati.corp.google.com/chrome-git-admins-ninja).
2.  The script runner needs to get added to the gerrit group
    [chromeos-partner-admins](https://chrome-internal-review.googlesource.com/admin/groups/23).
    Request to be added can be made to any member of chromeos-partner-admins.
3.  Install jq for json file parsing. \
    `$ sudo apt-get install jq`

### How to run the script

For a new program, manually create a {program}\_local_manifest.xml file and
commit to this script's directory. That local_manifest with get copied to all
project repos in the program.

To add resources for a program \
`$ ./create_partner_repo --program programName`

To add resource for a project \
`$ ./create_partner_repo --program programName --project projectName`

To apply ACLs to project's committer and access groups (--project is optional) \
`$ ./create_partner_repo --program programName --project projectName --run
acls`

To create and apply default permissions to gerrit groups (--project is optional)
\
`$ ./create_partner_repo --program programName --project projectName --run
gerritgroups`

To add a local_manifest.xml into the project repo \
`$ ./create_partner_repo --program programName --project projectName --run
localmanifest`

To create gs buckets and assign ACLs to them \
`$ ./create_partner_repo --program programName --project projectName --run
createprojectbuckets`

## `gen_project`

TODO
