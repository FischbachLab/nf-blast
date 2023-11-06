# NF-BLAST

A Nextflow script that will run BLAST and using fasta files on S3 and databases available on a shared filesystem (EFS).

```{bash}
aws batch submit-job \
    --job-name nf-blast-SH0002532-00280 \
    --job-queue priority-maf-pipelines \
    --job-definition nextflow-production \
    --container-overrides command=fischbachlab/nf-blast,\
"--query","s3://genomics-workflow-core/Results/HybridAssembly/MITI-MCB/SH0002532-00280/20230505/UNICYCLER/assembly.fasta",\
"--project","MITI-MCB",\
"--sample_name","SH0002532-00280",\
"--db","immeDB",\
"--prefix","20230822"
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

- the output is in the customized tabular format `'7 std qlen slen qcovs'`, where `3` non-standard columns have been added.
- e-values are calculated based on a `dbsize` of 1e6, to allow comparison between results from different databases.
- a maximum of `500` alignments are allowed per query.
- the query file is split into smaller chunnks of `1000` sequences each, before running a blast on each chunk in parallel and finally merging into a single output table.

## Using a `seedfile` to run Blast on multiple fasta files [PREFERRED]

Create a comma-separated `seedfile`, where first column is the sample name and second is the path to the fasta file. For example:

```bash
sample_name,fasta_file
SH0001852-00262,s3://genomics-workflow-core/Results/HybridAssembly/MITI-MCB/SH0001852-00262/20230120/UNICYCLER/assembly.fasta
SH0001328-00301,s3://genomics-workflow-core/Results/HybridAssembly/MITI-MCB/SH0001328-00301/20230610/UNICYCLER/assembly.fasta
SH0001374-00303,s3://genomics-workflow-core/Results/HybridAssembly/MITI-MCB/SH0001374-00303/20230602/UNICYCLER/assembly.fasta
SH0001378-00273,s3://genomics-workflow-core/Results/HybridAssembly/MITI-MCB/SH0001378-00273/20230602/UNICYCLER/assembly.fasta
SH0001421-00003,s3://genomics-workflow-core/Results/HybridAssembly/MITI-MCB/SH0001421-00003/20230602/UNICYCLER/assembly.fasta
SH0001515-00040,s3://genomics-workflow-core/Results/HybridAssembly/MITI-MCB/SH0001515-00040/UNICYCLER/assembly.fasta
```

```{bash}
aws batch submit-job \
    --job-name nf-blast-seedfile-2 \
    --job-queue priority-maf-pipelines \
    --job-definition nextflow-production \
    --container-overrides command=fischbachlab/nf-blast,\
"--seedfile","s3://genomics-workflow-core/Results/AMRFinderPlus/MITI-MCB/20231106/00_seedfile/20231106_seedfile.csv",\
"--db","immeDB",\
"--project","MITI-MCB",\
"--prefix","20231106"
```

Where: `20231106` is today's date in the format `YYYYMMDD`.
