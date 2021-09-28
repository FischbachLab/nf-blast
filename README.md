# NF-BLAST

A Nextflow script that will run BLAST and using fasta files on S3 and databases available on a shared filesystem (EFS).

```{bash}
aws batch submit-job \
    --profile maf \
    --job-name nf-blast-0825-2 \
    --job-queue default-maf-pipelines \
    --job-definition nextflow-production \
    --container-overrides command=s3://nextflow-pipelines/nf-blast,\
"--query","s3://nextflow-pipelines/blast/data/TY0000004.cons.fa",\
"--db","ncbi_16s"
```

## Available datbases

- `nt`
- `nr`
- `ncbi_16s`
- `silva` SSU v138.1
- `silva_nr` SSU v138.1

## By default

- the output is in the customized tabular format `'7 std qlen slen qcovs sscinames'`, where `4` non-standard columns have been added.
- e-values are calculated based on a `dbsize` of 1e6, to allow comparison between results from different databases.
- a maximum of `500` alignments are allowed per query.
- the query file is split into smaller chunnks of `1000` sequences each, before running a blast on each chunk in parallel and finally merging into a single output table.

