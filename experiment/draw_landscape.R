simple_hill <- readr::read_csv("simple_hill.csv")
lattice::wireframe(score ~ x * y, data = simple_hill)
