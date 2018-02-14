import sys
from glob import glob

import yaml
from invoke import task
from unipath import Path

import peaks


PROJ = Path(__file__).parent.absolute()
R_PKG = Path(PROJ, 'mountainclimbers')


@task(help=dict(experiment='yaml file by path or stem name with no extension'))
def run(ctx, experiment):
    """Run an experiment in "experiments/" or from a config file.

    Run an experiment by passing in a path to a config file. Experiments will
    be searched for in the experiments directory. To list available
    experiments, pass 'list' as the first argument. Experiments
    in this directory can be run by the stem name of the file. To run all the
    available experiments, pass 'all'.

        $ inv run path/to/my/exp-1.yaml  # run a single experiment
        $ inv run list                   # list experiments in "experiments/"
        $ inv run exp-1                  # run "experiments/exp-1.yaml"
        $ inv run all                    # run all available experiments
    """
    if experiment == 'list':
        print('Experiments:')
        for experiment in Path('experiments').listdir('*.yaml'):
            print(' - ' + experiment.stem)
        return
    elif experiment == 'all':
        experiments = Path('experiments').listdir('*.yaml')
    elif Path(experiment).exists():
        experiments = [Path(experiment)]
    else:
        experiment = Path('experiments', experiment + '.yaml')
        assert experiment.exists(), 'experiment %s not found' % experiment
        experiments = [experiment]

    for experiment in experiments:
        output = Path(R_PKG, 'data-raw', experiment.stem+'.csv')
        print('Running experiment { %s }' % experiment.stem)
        peaks.run_experiment(experiment, output=output)


@task
def install(ctx, verbose=False, use_data_too=False):
    """Install the mountainclimbers R package."""
    cmd = 'cd {R_pkg} && Rscript -e "{R_cmd}"'
    R_cmds = """\
    library(devtools)
    document()
    install()
    """

    if use_data_too:
        use_data(ctx, verbose=verbose)

    ctx.run(cmd.format(R_pkg=R_PKG, R_cmd=';'.join(R_cmds.split())),
            echo=verbose)

@task
def use_data(ctx, verbose=False):
    """Save the simulation results to the mountainclimbers R package."""
    cmd = 'cd {R_pkg} && Rscript data-raw/use-data.R'
    ctx.run(cmd.format(R_pkg=R_PKG), echo=verbose)


@task(help={'clear-cache': 'Clear knitr cache and figs before rendering.',
            'open-after': 'Open the report after creating it.',
            'skip-prereqs': 'Don\'t try to update custom prereqs.'})
def report(ctx, name, clear_cache=False, open_after=False, skip_prereqs=False):
    """Compile dynamic reports from the results of the experiments."""
    report_dir = Path('docs')

    all_reports = [Path(report) for report in
                   glob(Path(report_dir, '**/*.Rmd'), recursive=True)
                   if Path(report).isfile()]

    if name == 'list':
        print('Reports:')
        for report in all_reports:
            print(' - ' + report.stem)
        return
    elif name == 'all':
        reports = all_reports
    elif Path(name).exists():
        reports = [name]
    else:
        for report in all_reports:
            if report.stem == name:
                reports = [report]
                break
        else:
            raise AssertionError('Report "{}" not found'.format(name))

    if not skip_prereqs:
        ctx.run('Rscript -e "devtools::install_github(\'pedmiston/crotchet\')"')

    render_cmd = 'Rscript -e "rmarkdown::render(\'{}\')"'
    for report in reports:
        if clear_cache:
            ctx.run('rm -rf {p}/{n}*cache/ {p}/{n}*figs/'.format(
                        p=report.parent, n=name
                    ), echo=True)

        ctx.run(render_cmd.format(report))

        if open_after:
            output = Path(report.parent, report.stem + '.html')
            ctx.run('open {}'.format(output))
