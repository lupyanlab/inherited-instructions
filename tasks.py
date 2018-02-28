import os
from os import path
from ansible_vault import Vault
from glob import glob
from pathlib import Path
from invoke import Collection, task
import gspread
from oauth2client.service_account import ServiceAccountCredentials
import jinja2

@task
def save(ctx):
    """Save experiment data to R pkg."""
    cmd = 'cp {experiment_dir}/*.csv {r_pkg_data_raw}'
    experiment_dir = Path('experiment/data')
    r_pkg_data_raw = Path('data/data-raw/experiment')
    if not r_pkg_data_raw.is_dir():
        os.mkdir(str(r_pkg_data_raw))
    kwargs = dict(experiment_dir=experiment_dir,
                  r_pkg_data_raw=r_pkg_data_raw)
    ctx.run(cmd.format(**kwargs), echo=True)


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

@task(help={'clear-cache': 'Clear knitr cache and figs before rendering.',
            'open-after': 'Open the report after creating it.',
            'skip-prereqs': 'Don\'t try to update custom prereqs.'})
def make(ctx, name, clear_cache=False, open_after=False, skip_prereqs=False):
    """Compile dynamic reports from the results of the experiments."""
    docs = Path('docs')
    render_cmd = 'cd {docs} && Rscript -e "rmarkdown::render({rmd.name!r})"'
    clear_cmd = 'rm -rf {docs}/{rmd.stem}_cache/ {docs}/{rmd.stem}_files/'

    all_reports = [Path(report) for report in glob('{docs}/*.Rmd'.format(docs=docs))]
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

    for rmd in reports:
        if clear_cache:
            ctx.run(clear_cmd.format(docs=docs, rmd=rmd), echo=True)

        ctx.run(render_cmd.format(docs=docs, rmd=rmd))

@task
def get_subj_info(ctx, move_to_r_pkg=False):
    """Download subject info sheets as csvs."""
    gc = connect_google_sheets()

    dst_dir = 'data/data-raw/notes' if move_to_r_pkg else '.'
    if not Path(dst_dir).is_dir():
        Path(dst_dir).mkdir()

    dst = path.join(dst_dir, 'subj-info.csv')
    wks = gc.open('gems-subj-info').sheet1
    with open(dst, 'wb') as f:
        f.write(wks.export())

    dst_pilot = path.join(dst_dir, 'subj-info-pilot.csv')
    pilot = gc.open('gems-subj-info').worksheet('pilot')
    with open(dst_pilot, 'wb') as f:
        f.write(pilot.export())

@task
def get_survey_responses(ctx, move_to_r_pkg=False):
    """Download responses to post-experiment questionnaires as csvs."""
    gc = connect_google_sheets()

    dst_dir = 'data/data-raw/survey' if move_to_r_pkg else '.'
    if not Path(dst_dir).is_dir():
        Path(dst_dir).mkdir()

    dst = path.join(dst_dir, 'responses.csv')
    wks = gc.open('gems-survey-responses').sheet1
    with open(dst, 'wb') as f:
        f.write(wks.export())


def connect_google_sheets():
    password = open(os.environ['ANSIBLE_VAULT_PASSWORD_FILE']).read()
    json_data = Vault(password).load(open('secrets/lupyanlab.json').read())
    credentials = ServiceAccountCredentials.from_json_keyfile_dict(
            json_data,
            ['https://spreadsheets.google.com/feeds'])
    return gspread.authorize(credentials)



from data import tasks as data_tasks
# from bots import tasks as bots_tasks

ns = Collection()
ns.add_collection(data_tasks, 'R')
# ns.add_collection(bots_tasks, 'bots')

ns.add_task(configure)
ns.add_task(make)
ns.add_task(get_subj_info)
ns.add_task(get_survey_responses)
ns.add_task(save)
