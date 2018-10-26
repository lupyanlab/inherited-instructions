import pandas

coded = pandas.read_csv("coded.csv", skiprows=[0, 2])
coded = coded[["name"] + coded.columns[coded.columns.str.contains("instructions")].tolist()]

coded = coded.melt(id_vars="name", var_name="qualtrics_col", value_name="score")
coded = coded.join(coded.qualtrics_col.str.extract(r"instructions\ \((?P<row_ix>\d+)\)-(?P<dimension>Bar width|Orientation)"))
del coded["qualtrics_col"]
coded["row_ix"] = coded.row_ix.astype(int)

loop_merge = pandas.read_csv("instructions.csv")
coded = coded.merge(loop_merge)

coded.to_csv("instructions_coded.csv", index=False)
