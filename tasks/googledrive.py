import os
import itertools
from pathlib import Path

import gspread
import pandas
from ansible_vault import Vault
from invoke import task
from oauth2client.service_account import ServiceAccountCredentials

def connect_google_sheets():
    password = open(os.environ['ANSIBLE_VAULT_PASSWORD_FILE']).read()
    json_data = Vault(password).load(open('secrets/lupyanlab.json').read())
    credentials = ServiceAccountCredentials.from_json_keyfile_dict(
            json_data,
            ['https://spreadsheets.google.com/feeds'])
    return gspread.authorize(credentials)

def get_subj_info(move_to_r_pkg=False):
    """Download subject info sheets as csvs."""
    gc = connect_google_sheets()

    dst_dir = 'data/data-raw/notes' if move_to_r_pkg else '.'
    if not Path(dst_dir).is_dir():
        Path(dst_dir).mkdir()

    workbook = gc.open('gems-subj-info')
    for sheet_name in ['generation1', 'generation2', 'pilot']:
        dst = os.path.join(dst_dir, 'subj-info-%s.csv' % sheet_name)
        wks = workbook.worksheet(sheet_name)
        with open(dst, 'wb') as f:
          f.write(wks.export())

def get_survey_responses(move_to_r_pkg=False):
    """Download responses to post-experiment questionnaires as csvs."""
    gc = connect_google_sheets()

    dst_dir = 'data/data-raw/survey' if move_to_r_pkg else '.'
    if not Path(dst_dir).is_dir():
        Path(dst_dir).mkdir()

    dst = os.path.join(dst_dir, 'responses.csv')
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
