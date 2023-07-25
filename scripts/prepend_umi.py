#!/usr/bin/env python3

import argparse
import dnaio
import xopen


def main(args):
    # Open the input files
    forward = dnaio.open(args.forward, opener=xopen.xopen)
    umi = dnaio.open(args.umi, opener=xopen.xopen)

    # Open the output files
    fout = xopen.xopen(args.output, 'wb')

    for f, u, in zip(forward, umi):
        umi = u.sequence
        f.sequence = u.sequence + f.sequence
        f.qualities = u.qualities + f.qualities

        fout.write(f.fastq_bytes())

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('forward', help='fastq.gz file with forward reads')
    parser.add_argument('umi', help='fastq.gz file with UMI reads')
    parser.add_argument('output', help='output fastq.gz file')

    arguments = parser.parse_args()
    main(arguments)
