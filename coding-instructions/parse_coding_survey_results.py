from pathlib import Path
import pandas
import argparse

def melt_coding_survey_results(qualtrics_csv, loop_merge_csv):
    coded = pandas.read_csv(qualtrics_csv, skiprows=[0, 2])
    coded = coded[["name"] + coded.columns[coded.columns.str.contains("ratings")].tolist()]
    coded = coded.melt(id_vars="name", var_name="qualtrics_col", value_name="score")
    coded = coded.join(coded.qualtrics_col.str.extract(r"ratings\ \((?P<row_ix>\d+)\)-(?P<dimension>Bar width|Orientation)"))
    del coded["qualtrics_col"]
    coded["row_ix"] = coded.row_ix.astype(int)
    loop_merge = pandas.read_csv(loop_merge_csv)
    coded = coded.merge(loop_merge)
    return coded



if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument("--qualtrics", default="qualtrics.csv")
    parser.add_argument("--loop-merge")
    parser.add_argument("--output", required=False)

    args = parser.parse_args()
    coded = melt_coding_survey_results(args.qualtrics, args.loop_merge)

    if args.output is None:
        original = Path(args.loop_merge)
        args.output = "{}-coded.csv".format(original.stem)
    coded.to_csv(args.output, index=False)
