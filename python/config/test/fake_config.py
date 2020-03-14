import os

THIS_DIR = os.path.dirname(__file__)

CONFIG_BINARY = 'config.binaryproto'

FAKE_PROGRAM_CONFIG = '%s/fake_program/%s' % (THIS_DIR, CONFIG_BINARY)
FAKE_PROJECT_CONFIG = '%s/fake_project/%s' % (THIS_DIR, CONFIG_BINARY)
