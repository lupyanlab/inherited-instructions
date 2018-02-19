from glob import glob
from pathlib import Path
from invoke import Collection, task
import jinja2

@task
def configure(ctx):
    """Create environment file for working on this project."""
    dst = '.environment'
    template = jinja2.Template(open('environment.j2', 'r').read())

    venv = input("Path to venv: ")

    kwargs = dict(venv=venv)
    with open(dst, 'w') as f:
        f.write(template.render(**kwargs))

@task
def clean(ctx):
    """Clean caches."""
    ctx.run('find . -name "*.pyc" -exec rm {} \;', echo=True)

@task(help={'clear-cache': 'Clear knitr cache and figs before rendering.',
            'open-after': 'Open the report after creating it.',
            'skip-prereqs': 'Don\'t try to update custom prereqs.'})
def make(ctx, name, clear_cache=False, open_after=False, skip_prereqs=False):
    """Compile dynamic reports from the results of the experiments."""
    report_dir = Path('docs')

    all_reports = [Path(report) for report in
                   glob(str(Path(report_dir, '**/*.Rmd')), recursive=True)
                   if Path(report).isfile()]

    if name == 'list':
        print('Reports:')
        for report in all_reports:
            print(' - ' + report.stem)
        return
    elif name == 'all':
        reports = all_reports
    elif Path(name).exists():
        reports = [name]
    else:
        for report in all_reports:
            if report.stem == name:
                reports = [report]
                break
        else:
            raise AssertionError('Report "{}" not found'.format(name))

    if not skip_prereqs:
        ctx.run('Rscript -e "devtools::install_github(\'pedmiston/crotchet\')"')

    render_cmd = 'Rscript -e "rmarkdown::render(\'{}\')"'
    for report in reports:
        if clear_cache:
            ctx.run('rm -rf {p}/{n}*cache/ {p}/{n}*figs/'.format(
                        p=report.parent, n=name
                    ), echo=True)

        ctx.run(render_cmd.format(report))

        if open_after:
            output = Path(report.parent, report.stem + '.html')
            ctx.run('open {}'.format(output))


from data import tasks as data_tasks
from bots import tasks as bots_tasks

ns = Collection()
ns.add_collection(data_tasks, 'R')
ns.add_collection(bots_tasks, 'bots')

ns.add_task(configure)
ns.add_task(clean)
ns.add_task(make)
