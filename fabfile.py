from fabric.api import env
from fabric.operations import run, put

env.hosts = ['space-wizards.net']
env.user = 'space_wizards'

DEST_PATH = '/home/space_wizards/games/dungeon-wizard/'


def deploy():
    run('rm -rf %s' % DEST_PATH)
    run('mkdir -p %s' % DEST_PATH)
    put('dist/*', DEST_PATH)


