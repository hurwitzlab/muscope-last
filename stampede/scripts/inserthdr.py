#!/usr/bin/env python3
"""
This script inserts a header row into a BLAST output file. The header looks like this:
    query id, subject id, % identity, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score, query length, subject length

usage:
    python3 inserthdr.py test.fa-contigs.tab
"""
import argparse
import shutil


def main(target_fp):
    target_with_header_fp = target_fp + '.add-hdr'
    with open(target_fp, 'rt') as input_file, open(target_with_header_fp, 'wt') as output_file:
        inserthdr(input_file, output_file)

    # this function will not copy file metadata
    shutil.move(target_with_header_fp, target_fp)


def inserthdr(input_file, output_file):
    for line in input_file:
        output_file.write(line)
        if line.startswith('# batch 0'):
            output_file.write('query id\tsubject id\t% identity\talignment length\tmismatches\tgap opens\tq. start\tq. end\ts. start\ts. end\tevalue\tbit score\tquery length\tsubject length\n')


def get_args():
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('target_fp', metavar='FILE', help='path to file to which BLAST header will be added')
    args = arg_parser.parse_args()
    return args


if __name__ == '__main__':
    args = get_args()
    inserthdr(**args.__dict__)
