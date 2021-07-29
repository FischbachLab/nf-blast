#!/usr/bin/env nextflow

// If the user uses the --help flag, print the help text below
params.help = false

// Function which prints help message text
def helpMessage() {
    log.info"""
    Blast sequences against a database
    
    Required Arguments:
      --query               Query file in fasta format
      --db                  Blast database
      --blast_type          Which blast would you like to run? (default: blastn)
    Options:
      --output_folder       Folder to place analysis outputs (default ./midas)
      --chunksize           Number of sequences to be processed per node (default: 100)
    """.stripIndent()
}

// Show help message if the user specifies the --help flag at runtime
if (params.help){
    // Invoke the function above which prints the help message
    helpMessage()
    // Exit out and do not run anything else
    exit 0
}

// // Show help message if the user specifies a fasta file but not makedb or db
// if (params.fasta && ((params.db == null) || (params.makedb == null))){
//     // Invoke the function above which prints the help message
//     helpMessage()
//     // Exit out and do not run anything else
//     exit 0
// }

// // Make sure that the Midas database file can be found
// if (file(params.db).isEmpty()){

//     // Print a helpful log message
//     log.info"""
//     Cannot find the file specified by --db_midas ${params.db_midas}
//     """.stripIndent()

//     // Exit out and do not run anything else
//     exit 0
// }

Channel
  .fromPath(params.query)
  .ifEmpty { exit 1, "Cannot find matching fasta file" }

// Write a function to read the db parameter and get the full path from databases json file
// and error if database does not exist
if (params.db == "nt"){
  db_path = "/mnt/efs/databases/Blast/nt/db/nt"
} else if (params.db == "silva"){
  db_path = "/mnt/efs/databases/Blast/Silva/v138.1/blastdb_custom/silva138"
} else if (params.db == "silva_nr"){
  db_path = "/mnt/efs/databases/Blast/Silva/v138.1/blastdb_custom/silva138_nr"
}

println db_path

/*
 * Defines the pipeline inputs parameters (giving a default value for each for them) 
 * Each of the following parameters can be specified as command line options
 */


params.blast_type = "blastn"
params.output_folder = "test"
params.prefix = "TY0000004.cons"
params.chunksize = 50

out = "s3://genomics-workflow-core/Pipeline_Results/Blast/${params.output_folder}/${params.prefix}.${params.blast_type}.tsv"
/* 
 * Given the query parameter creates a channel emitting the query fasta file(s), 
 * the file is split in chunks containing as many sequences as defined by the parameter 'chunksize'.
 * Finally assign the result channel to the variable 'fasta_ch' 
 */
Channel
    .fromPath(params.query)
    .splitFasta(by: params.chunksize, file:true)
    .set { fasta_ch }


/* 
 * Executes a BLAST job for each chunk emitted by the 'fasta_ch' channel 
 * and creates as output a channel named 'top_hits' emitting the resulting 
 * BLAST matches  
 */
process blast {
    cpus 2
    memory 8.GB

    input:
    path 'query.fa' from fasta_ch

    output:
    file 'blast_result' into hits_ch

    // echo "Listing path to database ($db_dir):"
    // ls $db_dir

    script:
    """
    ${params.blast_type} \
      -num_threads  $task.cpus \
      -query query.fa \
      -db $db_path \
      -dbsize 1000000 \
      -num_alignments 500 \
      -outfmt '6 std qlen slen qcovs' > blast_result
    """
}


/* 
 * Collects all the sequences files into a single file 
 */ 
hits_ch
    .collectFile(name: out)

// process show_downloadable_databases {
//   // directives
//   // a container images is required
//   container "ncbi/blast:latest"

//   // compute resources for the Batch Job
//   cpus 1
//   memory '512 MB'

//   script:
//   """
//   update_blastdb.pl --source aws --showall > /mnt/efs/databases/NCBI/db_names.list
//   cat /mnt/efs/databases/NCBI/db_names.list
//   update_blastdb.pl -h
//   """
// }
 