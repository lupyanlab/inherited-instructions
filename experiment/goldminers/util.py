from itertools import product

def create_grid(n_rows, n_cols):
    """Create all row, col grid positions.

    Grid positions are given as positive indices starting at 0.
    Rows range from 0 to (n_rows-1).
    Columns range from 0 to (n_cols-1).

    Grid positions are [(0, 0), (0, 1), ..., (n_rows-1, n_cols-1)]
    """
    return product(range(n_rows), range(n_cols))
