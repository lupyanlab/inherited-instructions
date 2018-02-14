from pathlib import Path
from invoke import task

R_pkg = Path(__file__).absolute().parent

@task
def install(ctx, verbose=False, use_data_too=False):
    """Install the mountainclimbers R package."""
    cmd = 'cd {R_pkg} && Rscript -e {R_cmds!r}'
    R_cmds = """\
    library(devtools)
    document()
    install()
    """.split()

    if use_data_too:
        use_data(ctx, verbose=verbose)

    ctx.run(cmd.format(R_pkg=R_PKG, R_cmds=';'.join(R_cmds)),
            echo=verbose)

@task
def use_data(ctx, verbose=False):
    """Save the simulation results to the mountainclimbers R package."""
    cmd = 'cd {R_pkg} && Rscript data-raw/use-data.R'
    ctx.run(cmd.format(R_pkg=R_PKG), echo=verbose)
