from psychopy import visual


def create_gabors(window, positions, orientations, spatial_frequencies, **grating_stim_kwargs):
    gabors = []
    for pos, ori, sf in zip(positions, orientations, spatial_frequencies):
        gabor = visual.GratingStim(window, mask='circle',
                                   pos=pos, ori=ori, sf=sf,
                                   **grating_stim_kwargs)
        gabors.append(gabor)

    return gabors
