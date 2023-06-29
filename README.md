# NF-BLAST

A Nextflow script that will run BLAST and using fasta files on S3 and databases available on a shared filesystem (EFS).

```{bash}
aws batch submit-job \
    --profile maf \
    --job-name nf-blast-20221011.1 \
    --job-queue priority-maf-pipelines \
    --job-definition nextflow-production \
    --container-overrides command=s3://nextflow-pipelines/nf-blast,\
"--query","s3://nextflow-pipelines/blast/data/TY0000004.cons.fa",\
"--db","nt",
"--project","00_Test",
"--prefix","TY0000004"
```

## Sample Parameters for Nextflow Tower

```{json}
{
    "blast_type": "blastn",
    "db": "nt",
    "chunksize": 1000,
    "dbsize": 1000000,
    "outfmt": "'7 std qlen slen qcovs sscinames'",
    "max_aln": 500,
    "project": "00_Test",
    "prefix": "output-0929",
    "query": "s3://nextflow-pipelines/blast/data/TY0000004.cons.fa"
}
```

## Available databases

- `nt`- [Last Updated: 2022-10-11] version: 2022-10-01-01-05-02
- `nr` - [Last Updated: 2022-10-11] version: 2022-10-01-01-05-02
- `ncbi_16s` - [Last Updated: 2022-10-11] version: 2022-10-01-01-05-02
- `silva` SSU v138.1  - [Last Updated: 2021-07-22]
- `silva_nr` SSU v138.1  - [Last Updated: 2021-07-22]
- `immeDB` - [Last Updated: 2023-06-27]

## By default

- the output is in the customized tabular format `'7 std qlen slen qcovs sscinames'`, where `4` non-standard columns have been added.
- e-values are calculated based on a `dbsize` of 1e6, to allow comparison between results from different databases.
- a maximum of `500` alignments are allowed per query.
- the query file is split into smaller chunnks of `1000` sequences each, before running a blast on each chunk in parallel and finally merging into a single output table.

## Running on multiple fasta files

### Option 1: Combine your fasta files into a single file

If you're sure that all the contig names in your fasta files are unique (up to the first space), you can combine them into a single fasta file and run the pipeline on that file.

### Option 2: Run the pipeline on each fasta file separately

If you're not sure that all the contig names in your fasta files are unique, you can run the pipeline on each fasta file separately.

You will need:

- the latest version of [GNU parallel](https://ftpmirror.gnu.org/parallel/parallel-latest.tar.bz2) installed to make your life easier.
- to update the [`run_multi_file_blast.sh`](scripts/run_multi_file_blast.sh) script to work for your use case. Please feel free to consult with Sunit/Xiandong if you need help with this.

Here is an example of the command that submits one job per fasta file:

```{bash}
aws s3 ls s3://maf-users/Daisy_Lee/abricate/20230614/ \
| awk '{print $4}' \
| parallel -j 4 "bash run_multi_file_blast.sh {}" &> run_multi_file_blast.log &
```

>**NOTE 1**: The above command will run 4 jobs in parallel. You can change the number of jobs to run in parallel by changing the `-j` parameter.
>
>**NOTE 2**: The above command has only been tested on a Mac or Unix system. It may not work on Windows.
