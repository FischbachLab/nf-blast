NF-BLAST
====================

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
