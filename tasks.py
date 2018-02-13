from invoke import Collection, task
from experiment import tasks as exp

ns = Collection()
ns.add_collection(exp, 'exp')

@task
def clean(ctx):
    """Clean caches."""
    ctx.run('find . -name "*.pyc" -exec rm {} \;', echo=True)

ns.add_task(clean)
