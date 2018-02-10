import pytest

from goldminers import create_positions

def test_create_single_position():
    positions = create_positions(n_rows=1, n_cols=1, win_size=(100, 100))
    assert len(positions) == 1
    assert positions[0] == (-50, -50)

def test_create_four_positions():
    positions = create_positions(n_rows=2, n_cols=2, win_size=(100, 100))
    assert len(positions) == 4
    assert set(positions) == set([(-50, -50), (-50, 50), (50, -50), (50, 50)])

@pytest.mark.parametrize("n_rows,n_cols,n_expected_positions", [
    (1, 1, 1),
    (2, 2, 4),
    (5, 5, 25),
])
def test_create_n_positions(n_rows, n_cols, n_expected_positions):
    assert len(create_positions(n_rows, n_cols, win_size=(100, 100))) == n_expected_positions
