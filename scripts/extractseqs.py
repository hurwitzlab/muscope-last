#!/usr/bin/env python3
"""
extractseqs.py

This script is part of the muSCOPE-LAST CyVerse application.

Read a LAST output file to get sequence hit ids for the reference sequences. Extract the reference
sequences corresponding to each hit from the original reference file(s) and write them to a file.

The muSCOPE-LAST application generates LAST output files with names like
     + test.fa-contigs.tab
     + test.fa-genes.tab
     + test.fa-proteins.tab
where 'test.fa' is the name of the input file to LAST and contigs, genes and proteins are the Ohana reference
databases.

Each .tab file looks like this:
    # LAST version 833
    #
    # a=7 b=1 A=7 B=1 e=34 d=-1 x=33 y=9 z=33 D=1e+06 E=22.3617
    # R=01 u=2 s=2 S=0 M=0 T=0 m=10 l=1 n=10 k=1 w=1000 t=0.910239 j=3 Q=0
    # /work/04658/jklynch/ohana/last/HOT_genes
    # Reference sequences=42682828 normal letters=22359609694
    # lambda=1.09602 K=0.335388
    #
    # A C G T
    # A 1 -1 -1 -1
    # C -1 1 -1 -1
    # G -1 -1 1 -1
    # T -1 -1 -1 1
    #
    # Fields: query id, subject id, % identity, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score, query length, subject length
    # batch 0
    A HOT229_1_0200m_c10096_4 100.00 147 0 0 1 147 400 546 8.6e-68 234 147 546
    A HOT232_1_0200m_rep_c270553_3 100.00 147 0 0 1 147 400 546 8.6e-68 234 147 546

The second column is parsed to extract the reference sample name from the sequence id (e.g. `HOT234_1_0200m`). All
matched sequences are extracted from the reference sample FASTA files and written to a file.
"""

import argparse
import collections
import itertools
import os
import re

from Bio import SeqIO



def main(last_output_fp, ohana_sequence_dp, ohana_hit_output_dp, last_hit_limit):
    """Extract sequences corresponding to LAST hits.

    :param last_output_fp: (str) file path to a LAST output file
    :param ohana_sequence_dp: (str) directory path to Ohana LAST reference fasta files
    :param ohana_hit_output_dp: (str) directory path for sequence file output
    :param last_hit_limit: (int) maximum number of LAST hits to process, None for all hits
    :return:
    """

    if not os.path.isfile(last_output_fp):
        print('LAST output file "{}" does not exist.'.format(last_output_fp))
        exit(1)
    if not os.path.isdir(ohana_sequence_dp):
        print('LAST database directory "{}" does not exist.'.format(ohana_sequence_dp))
        exit(1)
    if not os.path.isdir(ohana_hit_output_dp):
        print('Sequence output directory "{}" will be created.'.format(ohana_hit_output_dp))
        os.makedirs(ohana_hit_output_dp, exist_ok=True)

    # set up file paths
    last_input_file_name, seq_type = parse_muscope_last_output_filename(last_output_fp)


    last_input_base_name = os.path.basename(last_input_file_name)
    seq_type_ext = {'contigs': '.fa', 'genes': '.fna', 'proteins': '.faa'}
    last_ref_sample_fasta_file_template = os.path.join(
        ohana_sequence_dp,
        '{refsample}',
        seq_type + seq_type_ext[seq_type]
    )
    output_file_path_template = os.path.join(
        ohana_hit_output_dp,
        last_input_base_name + '-{refsample}-' + seq_type + seq_type_ext[seq_type]
    )

    # parse the LAST output file
    with open(last_output_fp, 'rt') as last_output_file:
        last_refdb_hits = get_last_reference_hits(last_output_file=last_output_file, last_output_row_limit=last_hit_limit)
    print('finished parsing LAST output file "{}"'.format(last_output_fp))

    # find each hit from the LAST output in the corresponding LAST reference sample FASTA files
    # and copy each sequence to a file
    for last_ref_sample_name, sample_sequence_ids in sorted(last_refdb_hits.items()):
        last_ref_sample_fasta_fp = last_ref_sample_fasta_file_template.format(refsample=last_ref_sample_name)
        if not os.path.exists(last_ref_sample_fasta_fp):
            print('ERROR: LAST reference "{}" does not exist'.format(last_ref_sample_fasta_fp))
        else:
            print('extracting sequence hits from "{}"'.format(last_ref_sample_fasta_fp))
            output_fp = output_file_path_template.format(refsample=last_ref_sample_name)
            with open(last_ref_sample_fasta_fp, 'rt') as sample_fasta_file, \
                    open(output_fp, 'wt') as sample_sequence_output_file:

                for i, seq in enumerate(find_sequences(sample_sequence_ids, sample_fasta_file)):
                    SeqIO.write(seq, sample_sequence_output_file, 'fasta')

                print('wrote {} sequence(s) to file "{}"'.format(i+1, output_fp))


def parse_muscope_last_output_filename(last_output_fp):
    """Parse muscope-last LAST output file names such as 'test.fa-contigs.tab' and return the name of the LAST
    input file ('test.fa') and the sequence type ('contigs').

    :param last_output_fp: (str)
    :return: (str, str) tuple of LAST input file name and sequence type
    """
    last_output_filename_pattern = re.compile(r'(?P<input>.+)-(?P<seq_type>(contigs|genes|proteins))\.tab')
    try:
         _, last_output_filename = os.path.split(last_output_fp)
         return last_output_filename_pattern.search(last_output_filename).group('input', 'seq_type')
    except Exception as e:
        print('  failed to parse LAST output file name "{}"'.format(last_output_fp))
        raise e


def find_sequences(sequence_ids, fasta_file):
    """Search fasta_file for sequence ids in sequence_ids and write the corresponding sequence and yield each
    sequence record that is found.

    :param sequence_ids: (set of str)
    :param fasta_file: (file-like object)
    :yield: (biopython sequence object)
    """
    remaining_sequence_ids = set(sequence_ids)
    for seq in SeqIO.parse(fasta_file, 'fasta'):
        if seq.id in remaining_sequence_ids:
            remaining_sequence_ids.remove(seq.id)
            yield seq

            if len(remaining_sequence_ids) == 0:
                break
    return


def get_last_reference_hits(last_output_file, last_output_row_limit):
    """Read the specified LAST output file to build a dictionary with Ohana reference database names as keys and
    sets of sequence ids as values.

    LAST output files look like this:
        # LAST version 833
        #
        # a=7 b=1 A=7 B=1 e=34 d=-1 x=33 y=9 z=33 D=1e+06 E=22.3617
        # R=01 u=2 s=2 S=0 M=0 T=0 m=10 l=1 n=10 k=1 w=1000 t=0.910239 j=3 Q=0
        # /work/04658/jklynch/ohana/last/HOT_genes
        # Reference sequences=42682828 normal letters=22359609694
        # lambda=1.09602 K=0.335388
        #
        # A C G T
        # A 1 -1 -1 -1
        # C -1 1 -1 -1
        # G -1 -1 1 -1
        # T -1 -1 -1 1
        #
        # Fields: query id, subject id, % identity, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score, query length, subject length
        # batch 0
        A HOT229_1_0200m_c10096_4 100.00 147 0 0 1 147 400 546 8.6e-68 234 147 546
        A HOT232_1_0200m_rep_c270553_3 100.00 147 0 0 1 147 400 546 8.6e-68 234 147 546

    The dictionary generated by this function looks like this:
        {
            'HOT234_1_0200m': {'HOT234_1_0200m_rep_c55158_2', 'HOT234_1_0200m_c10096_4'},
            'HOT238_1c_0200m': {'HOT238_1c_0200m_c3_1', 'HOT238_1c_0200m_rep_c260499_1'}
        }

    :param last_output_file: (file-like object) LAST output file
    :param last_output_row_limit: (int) maximum number of LAST output rows to process, None to process all rows
    :return: dictionary of Ohana reference database names mapped to sets of sequence ids
    """
    last_db_hits = collections.defaultdict(set)

    subject_id_pattern = re.compile(r'^(?P<sample_id>HOT\d+_(\d*c?_)?\d+m)')
    for i, last_output_row in enumerate(
            itertools.islice(
                itertools.filterfalse(lambda x: x.startswith('#'), last_output_file),
                last_output_row_limit)):
        try:
            _, subject_id, _ = last_output_row.strip().split('\t', maxsplit=2)
            sample_id = subject_id_pattern.match(subject_id).group('sample_id')
            last_db_hits[sample_id].add(subject_id)
        except Exception as e:
            print('failed to parse row {}: "{}"'.format(i+1, last_output_row))
            raise e

    row_count = sum([len(sequences) for sequences in last_db_hits.values()])
    print('finished parsing {} rows of LAST output'.format(row_count))

    return last_db_hits


def get_args():
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('last_output_fp', metavar='FILE', help='file of LAST hits')
    arg_parser.add_argument('ohana_sequence_dp', metavar='DIR', help='directory of Ohana contigs, genes, proteins')
    arg_parser.add_argument('ohana_hit_output_dp', metavar='DIR', help='directory for Ohana LAST hit output')
    arg_parser.add_argument(
        '-limit', '--last-hit-limit', type=int, default=None,  help='extract only the first <last-hit-limit> LAST hits')
    args = arg_parser.parse_args()
    print(args)
    return args


if __name__ == '__main__':
    #test_last_output_dp = '/home/jklynch/host/project/muscope/apps/test-last-output/test.fa-proteins.tab'
    #test_last_db_fasta_dp = '/home/jklynch/host/project/muscope/ohana/'
    #test_sequence_output_dp = '/home/jklynch/host/project/muscope/apps/test-sequence-output/'
    args = get_args()
    main(**args.__dict__)
