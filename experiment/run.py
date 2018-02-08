#!/usr/bin/env python
import goldminers

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--subject-id', '-s', default='')
    parser.add_argument('--instructions-condition', '-i', default='')
    args = parser.parse_args()
    goldminers.run(**args.__dict__)
