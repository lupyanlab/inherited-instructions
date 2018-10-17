import os
from glob import glob
from pathlib import Path

from invoke import Collection, task
from ansible_vault import Vault
import pandas
import jinja2

from tasks.googledrive import get_subj_info, get_survey_responses


@task
def configure(ctx):
    """Create environment file for working on this project."""
    dst = '.env'
    template = jinja2.Template("export ANSIBLE_VAULT_PASSWORD_FILE={{ password_file }}")
    password_file = input("Path to password file: ")
    kwargs = dict(password_file=password_file)
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

    instructions_dir = Path('experiment/data/instructions')
    r_pkg_instructions_dir = Path('data/data-raw/instructions')
    if not r_pkg_instructions_dir.is_dir():
        os.mkdir(str(r_pkg_instructions_dir))
    ctx.run(f'cp {instructions_dir}/*.txt {r_pkg_instructions_dir}', echo=True)

    simluations_dir = Path('experiment/data/simulations')
    r_pkg_simulations_dir = Path('data/data-raw/simulations')
    if not r_pkg_simulations_dir.is_dir():
        os.mkdir(str(r_pkg_simulations_dir))
    ctx.run(f'cp {simluations_dir}/*.csv {r_pkg_simulations_dir}', echo=True)

    if not no_subj_info:
        get_subj_info(move_to_r_pkg=True)

    if not no_survey:
        get_survey_responses(move_to_r_pkg=True)


@task(help={'clear-cache': 'Clear knitr cache and figs before rendering.',
            'open-after': 'Open the report after creating it.'})
def make_doc(ctx, name, clear_cache=False, open_after=False):
    """Compile dynamic documents."""
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


@task
def save_instructions(ctx):
    instructions = []
    for instr in Path("experiment/data/instructions").glob("*.txt"):
        instructions.append(dict(
            subj_id=instr.stem,
            instructions=open(instr, "r").read().strip()
        ))
    (pandas.DataFrame(instructions)[["subj_id", "instructions"]]
           .sort_values(by="subj_id")
           .to_csv("coding-instructions/instructions.csv", index=False))

ns = Collection()

# Add tasks defined in this file
ns.add_task(configure)
ns.add_task(make_doc)
ns.add_task(save_exp)
ns.add_task(save_instructions)

# Add tasks defined in other files

from data import tasks as data_tasks
ns.add_collection(data_tasks, 'R')

# from bots import tasks as bots_tasks
# ns.add_collection(bots_tasks, 'bots')
