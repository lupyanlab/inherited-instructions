import os
from pathlib import Path

from invoke import Collection, task
from ansible_vault import Vault
import pandas
import jinja2

from tasks.googledrive import get_subj_info, get_survey_responses


@task
def configure(ctx):
    """Create environment file for working on this project."""
    dst = '.environment'
    template = jinja2.Template(open('environment.j2', 'r').read())

    venv = input("Path to venv: ")
    password_file = input("Path to password file: ")

    kwargs = dict(venv=venv, password_file=password_file)
    with open(dst, 'w') as f:
        f.write(template.render(**kwargs))


@task
def save_exp(ctx, no_subj_info=False, no_survey=False):
    """Save experiment data to R pkg."""
    cmd = 'cp {experiment_dir}/*.csv {r_pkg_data_raw}'
    experiment_dir = Path('experiment/data')
    r_pkg_data_raw = Path('data/data-raw/experiment')
    if not r_pkg_data_raw.is_dir():
        os.mkdir(str(r_pkg_data_raw))
    kwargs = dict(experiment_dir=experiment_dir,
                  r_pkg_data_raw=r_pkg_data_raw)
    ctx.run(cmd.format(**kwargs), echo=True)

    if not no_subj_info:
        get_subj_info(move_to_r_pkg=True)

    if not no_survey:
        get_survey_responses(move_to_r_pkg=True)


@task(help={'clear-cache': 'Clear knitr cache and figs before rendering.',
            'open-after': 'Open the report after creating it.'})
def make_doc(ctx, name, clear_cache=False, open_after=False):
    """Compile dynamic reports from the results of the experiments."""
    docs = Path('docs')
    render_cmd = 'cd {docs} && Rscript -e "rmarkdown::render({rmd.name!r}, output_format={output_format!r}, output_file={output.name!r})"'
    clear_cmd = 'rm -rf {docs}/{rmd.stem}_cache/ {docs}/{rmd.stem}_files/'

    if name == 'list':
        all_reports = glob('{docs}/*.Rmd'.format(docs=docs))
        print('Reports:')
        for report in all_reports:
            print(' - ' + Path(report).stem)
        return

    output = Path(name)

    try:
      output_format = {'.pdf': 'bookdown::pdf_document2'}[output.suffix]
    except KeyError:
      raise AssertionError(f'output format "{output.suffix}" not defined')

    rmd = Path(f'{docs}/{output.stem}.Rmd')
    assert rmd.exists(), f'report "{rmd}" not found'

    if clear_cache:
        ctx.run(clear_cmd.format(docs=docs, rmd=rmd), echo=True)

    ctx.run(render_cmd.format(docs=docs, rmd=rmd, output=output, output_format=output_format), echo=True)

    if open_after:
        ctx.run(f'open {docs}/{output.name}', echo=True)

from data import tasks as data_tasks
# from bots import tasks as bots_tasks
from tasks.googledrive import update_subj_info

ns = Collection()
ns.add_collection(data_tasks, 'R')
# ns.add_collection(bots_tasks, 'bots')

ns.add_task(configure)
ns.add_task(make_doc)
ns.add_task(save_exp)
ns.add_task(update_subj_info)