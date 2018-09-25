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
    dst = os.path.join(dst_dir, 'subj-info.csv')
    wks = workbook.worksheet('Fall2018')
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
