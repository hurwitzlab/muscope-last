import io

import extractseqs
import inserthdr


last_output_text = """\
# LAST version 833
#
# a=7 b=1 A=7 B=1 e=34 d=-1 x=33 y=9 z=33 D=1e+06 E=22.3617
# R=01 u=2 s=2 S=0 M=0 T=0 m=10 l=1 n=10 k=1 w=1000 t=0.910239 j=3 Q=0
# /work/04658/jklynch/ohana/last/HOT_genes
# Reference sequences=42682828 normal letters=22359609694
# lambda=1.09602 K=0.335388
#
#    A  C  G  T
# A  1 -1 -1 -1
# C -1  1 -1 -1
# G -1 -1  1 -1
# T -1 -1 -1  1
#
# Fields: query id, subject id, % identity, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score, query length, subject length
# batch 0
A\tHOT234_1_0200m_c10096_4\t100.00\t147\t0\t0\t1\t147\t400\t546\t8.6e-68\t234\t147\t546
A\tHOT234_1_0200m_rep_c55158_2\t100.00\t147\t0\t0\t1\t147\t400\t546\t8.6e-68\t234\t147\t546
A\tHOT238_1c_0200m_c3_1\t100.00\t147\t0\t0\t1\t147\t1\t147\t8.6e-68\t234\t147\t147
A\tHOT238_1c_0200m_rep_c260499_1\t100.00\t147\t0\t0\t1\t147\t1\t147\t8.6e-68\t234\t147\t147"""

fasta_text = """\
>A
GTGC
>B
ATGC
>C
ATGG"""


def test_get_last_hits():
    last_output_file = io.StringIO(last_output_text)
    last_hits = extractseqs.get_last_reference_hits(last_output_file=last_output_file, last_output_row_limit=None)
    assert len(last_hits) == 2
    assert len(last_hits['HOT234_1_0200m']) == 2
    assert 'HOT234_1_0200m_rep_c55158_2' in last_hits['HOT234_1_0200m']
    assert 'HOT234_1_0200m_c10096_4' in last_hits['HOT234_1_0200m']
    assert len(last_hits['HOT238_1c_0200m']) == 2
    assert 'HOT238_1c_0200m_c3_1' in last_hits['HOT238_1c_0200m']
    assert 'HOT238_1c_0200m_rep_c260499_1' in last_hits['HOT238_1c_0200m']


def test_get_last_hits__limit():
    last_output_file = io.StringIO(last_output_text)
    last_hits = extractseqs.get_last_reference_hits(last_output_file=last_output_file, last_output_row_limit=3)
    assert len(last_hits) == 2
    assert len(last_hits['HOT234_1_0200m']) == 2
    assert 'HOT234_1_0200m_rep_c55158_2' in last_hits['HOT234_1_0200m']
    assert 'HOT234_1_0200m_c10096_4' in last_hits['HOT234_1_0200m']
    assert len(last_hits['HOT238_1c_0200m']) == 1
    assert 'HOT238_1c_0200m_c3_1' in last_hits['HOT238_1c_0200m']


def test_find_sequences():
    fasta_file = io.StringIO(fasta_text)
    search_results = list(extractseqs.find_sequences(['C', 'B', 'A'], fasta_file=fasta_file))
    assert len(search_results) == 3
    assert search_results[0].id == 'A'
    assert search_results[1].id == 'B'
    assert search_results[2].id == 'C'


def test_find_sequences__first():
    fasta_file = io.StringIO(fasta_text)
    search_results = list(extractseqs.find_sequences(['A'], fasta_file=fasta_file))
    assert len(search_results) == 1
    assert search_results[0].id == 'A'


def test_find_sequences__middle():
    fasta_file = io.StringIO(fasta_text)
    search_results = list(extractseqs.find_sequences(['B'], fasta_file=fasta_file))
    assert len(search_results) == 1
    assert search_results[0].id == 'B'


def test_find_sequences__last():
    fasta_file = io.StringIO(fasta_text)
    search_results = list(extractseqs.find_sequences(['C'], fasta_file=fasta_file))
    assert len(search_results) == 1
    assert search_results[0].id == 'C'


def test_parse_last_output_filename__contigs():
    last_input_file_name, seq_type = extractseqs.parse_muscope_last_output_filename('/some/dir/test.fa-contigs.tab')
    assert last_input_file_name == 'test.fa'
    assert seq_type == 'contigs'


def test_parse_last_output_filename__genes():
    last_input_file_name, seq_type = extractseqs.parse_muscope_last_output_filename('/some/dir/test.fa-genes.tab')
    assert last_input_file_name == 'test.fa'
    assert seq_type == 'genes'


def test_parse_last_output_filename__proteins():
    last_input_file_name, seq_type = extractseqs.parse_muscope_last_output_filename('/some/dir/test.fa-proteins.tab')
    assert last_input_file_name == 'test.fa'
    assert seq_type == 'proteins'


def test_insrthdr():
    input_file = io.StringIO(last_output_text)
    output_file = io.StringIO()
    inserthdr.inserthdr(input_file, output_file)
    output_file_text = output_file.getvalue()
    output_file_text_lines = output_file_text.splitlines()
    print(output_file_text)
    assert output_file_text_lines[16].startswith('query id')
