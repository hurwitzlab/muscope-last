import argparse
import itertools
import os

from Bio import SeqIO

from sqlalchemy import Column, String
from sqlalchemy import create_engine

from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker


Base = declarative_base()


class OhanaSequence(Base):
    __tablename__ = 'sequence'

    id = Column(String, primary_key=True)
    seq = Column(String)


def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx"
    args = [iter(iterable)] * n
    return itertools.zip_longest(*args, fillvalue=fillvalue)


def get_args():
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('-i', '--input-file-path', metavar='FILE', help='input sequence file path')
    arg_parser.add_argument('-o', '--output-dir', metavar='DIR', help='output directory for SQLite db files')
    args = arg_parser.parse_args()
    return args


def build_seq_dbs(sqlite_db_dir, fasta_fp):
    sequence_group_count = 100000
    #fasta_fp = '/home/jklynch/host/project/muscope/ohana/HOT224_1_0025m/HOT224_1_0025m.fa'
    fasta_dir_path, fasta_filename = os.path.split(fasta_fp)
    _, fasta_parent_dir = os.path.split(fasta_dir_path)
    fasta_basename, fasta_ext = os.path.splitext(fasta_filename)

    sqlite_db_filename = '{}_{}.db'.format(fasta_parent_dir, fasta_basename)
    sqlite_db_fp = os.path.join(sqlite_db_dir, sqlite_db_filename)
    sqlite_db_url = 'sqlite:///{}'.format(sqlite_db_fp)
    print('SQLite db URL: {}'.format(sqlite_db_url))
    engine = create_engine(sqlite_db_url, echo=False)
    Base.metadata.create_all(engine)
    session_maker = sessionmaker(bind=engine)
    session = session_maker()

    with open(fasta_fp, 'rt') as fasta_file:
        for i, sequence_group in enumerate(grouper(SeqIO.parse(fasta_file, 'fasta'), sequence_group_count)):
            # for seq in sequence_group:
            #    print(seq)
            session.add_all(
                (OhanaSequence(id=seq.id, seq=str(seq.seq)) for seq in sequence_group if seq is not None)
            )

            session.commit()
            print('committed {} sequences'.format((i + 1) * sequence_group_count))
            break


if __name__ == '__main__':
    args = get_args()
    build_seq_dbs(**args.__dict__)