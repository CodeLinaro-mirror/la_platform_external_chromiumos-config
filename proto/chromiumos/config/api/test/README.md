# [DEPRECATED] Test/Lab APIs/protos

Currently, most/all of these protos are slated for either deprecation or
migration.

For what were originally TLS/RTD based APIs/proto-defs,
see src/config/proto/chromiumos/test as the new location for the new service
definitions (which are not broken up into smaller services).

For TLW, this will eventually be migrated to:
src/config/proto/chromiumos/test as the new location, but also broken up a
bit (e.g. caching service will be separated from inventory access).
