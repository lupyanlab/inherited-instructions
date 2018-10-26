#!/usr/bin/env python
import os
import io
import json
import shutil
import pathlib
import zipfile
import requests


def export_qualtrics_responses(survey_name, survey_id, dst, use_labels=False):
    """Export survey responses via the Qualtrics API."""
    # Get Qualtrics API token from the environment
    api_token = os.environ.get("QUALTRICS_API_TOKEN")

    # Set static parameters
    data_center = "co1"
    download_request_url = (
        f"https://{data_center}.qualtrics.com/API/v3/responseexports/"
    )
    headers = {"content-type": "application/json", "x-api-token": api_token}

    # Create data export
    file_format = "csv"
    download_request_params = dict(
        format="csv", surveyId=survey_id, useLabels=use_labels
    )
    download_request_payload = json.dumps(download_request_params)
    download_request_response = requests.post(
        download_request_url, data=download_request_payload, headers=headers
    )
    progress_id = download_request_response.json()["result"]["id"]

    # Check on data export progress and wait until export is ready
    request_check_progress = 0
    progress_status = "in progress"
    while request_check_progress < 100 and progress_status is not "complete":
        request_check_url = download_request_url + progress_id
        request_check_response = requests.request(
            "GET", request_check_url, headers=headers
        )
        request_check_progress = request_check_response.json()["result"][
            "percentComplete"
        ]

    # Download and unzip the file
    request_download_url = download_request_url + progress_id + "/file"
    request_download = requests.get(request_download_url, headers=headers, stream=True)
    zipfile.ZipFile(io.BytesIO(request_download.content)).extractall()

    # Move the extracted file to the final location
    extracted_csv = f"{survey_name}.csv"
    dst = pathlib.Path(dst)
    if not dst.parent.is_dir():
        dst.parent.mkdir()
    shutil.move(extracted_csv, dst)


if __name__ == "__main__":
    export_qualtrics_responses(
        survey_name="coding-instructions",
        survey_id="SV_5yY9fVIromzWXjf",
        dst="coded.csv",
    )
