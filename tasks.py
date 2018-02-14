from pathlib import Path
from invoke import Collection, task
import jinja2
from bots import tasks as bots_tasks

ns = Collection()
ns.add_collection(bots_tasks, 'bots')

@task
def configure(ctx):
    """Create environment file for working on this project."""
    dst = '.environment'
    template = jinja2.Template(open('environment.j2', 'r').read())

    venv = input("Path to venv: ")
    bots = input("Path to bots: ")

    kwargs = dict(venv=venv, bots=bots)
    with open(dst, 'w') as f:
        f.write(template.render(**kwargs))

@task
def clean(ctx):
    """Clean caches."""
    ctx.run('find . -name "*.pyc" -exec rm {} \;', echo=True)

ns.add_task(configure)
ns.add_task(clean)
