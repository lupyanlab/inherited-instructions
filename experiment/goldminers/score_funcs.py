
def simple_hill(grid_pos):
    """Get the height of a simple hill with peak at (50, 50)."""
    x, y = grid_pos
    return (-x**2) - (y**2) + (100*x) + (100*y)
