from goldminers import Landscape, SimpleHill

def test_convert_landscape_to_tidy_data():
    landscape = Landscape(n_rows=2, n_cols=2, score_func=lambda (x,y): 1)
    tidy_data = landscape.to_tidy_data()
    assert len(tidy_data) == 4
    assert tidy_data.columns.tolist() == 'x y ori sf score'.split()

def test_get_score_on_simple_hill():
    simple_hill = SimpleHill()
    assert simple_hill.get_score((50, 50)) == 5000
