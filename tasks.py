import os
import itertools
from os import path
from ansible_vault import Vault
from glob import glob
from pathlib import Path
from invoke import Collection, task
import gspread
import pandas
from oauth2client.service_account import ServiceAccountCredentials
import jinja2


@task
def save_exp(ctx):
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
            'open-after': 'Open the report after creating it.'})
def make_doc(ctx, name, clear_cache=False, open_after=False):
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

    workbook = gc.open('gems-subj-info')
    for sheet_name in ['generation1', 'generation2', 'pilot']:
        dst = path.join(dst_dir, 'subj-info-%s.csv' % sheet_name)
        wks = workbook.worksheet(sheet_name)
        with open(dst, 'wb') as f:
          f.write(wks.export())


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


@task
def update_subj_info(ctx):
    """Update the subj info sheet.

    Assumes the pos lists have already been exported via:

        experiment/$ inv exp.write-pos-lists  # creates "pos-lists.txt"
    """

    pos_lists = 'experiment/pos-lists.txt'
    pos_list_strs = [pos_list_str.strip() for pos_list_str in open(pos_lists)]
    pos_list_ixs = range(1, len(pos_list_strs))

    instructions_conditions = ['orientation', 'spatial_frequency']

    subj_info = pandas.DataFrame.from_records(
        list(itertools.product(pos_list_ixs, instructions_conditions)),
        columns=['starting_pos_list_ix', 'instructions_condition']
    ).sort_values(['starting_pos_list_ix', 'instructions_condition'])

    gc = connect_google_sheets()
    wb = gc.open('gems-subj-info')
    ws = wb.worksheet('generation2')


    cells = ws.range(f'D2:D{2+len(subj_info.instructions_condition)}')
    for cell, value in zip(cells, subj_info.instructions_condition):
        cell.value = value
    ws.update_cells(cells)

    cells = ws.range(f'E2:E{2+len(subj_info.starting_pos_list_ix)}')
    for cell, value in zip(cells, subj_info.starting_pos_list_ix):
        cell.value = value
    ws.update_cells(cells)



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
ns.add_task(make_doc)
ns.add_task(get_subj_info)
ns.add_task(get_survey_responses)
ns.add_task(save_exp)
ns.add_task(update_subj_info)
