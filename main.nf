#!/usr/bin/env nextflow
nextflow.enable.dsl=1
// If the user uses the --help flag, print the help text below
params.help = false

// Function which prints help message text
def helpMessage() {
    log.info"""
    Blast sequences against a database
    
    Required Arguments:
      Multiple files:
      --seedfile            CSV file with sample_name and fasta_file columns; redundant with --query and --sample_name
      
      One sample/file at a time:
      --query               Query file in fasta format; redundant with --seedfile
      --sample_name         Sample name; redundant with --seedfile

      Blast arguments:
      --db                  Blast database
      --blast_type          Which blast would you like to run? (default: ${params.blast_type})
      --prefix              Output prefix (default: ${params.prefix})
      --project             Folder to place analysis outputs (default: ${params.project})
    
    Options
      --chunksize           Number of sequences to be processed per node (default: ${params.chunksize})
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
if ((params.db == null) || (params.blast_type == null)){
    // Invoke the function above which prints the help message
    helpMessage()
    // Exit out and do not run anything else
    exit 1
}

if ((params.query  == null) && (params.seedfile == null)){
    // Invoke the function above which prints the help message
    helpMessage()
    // Exit out and do not run anything else
    exit 1
}


// Write a function to read the db parameter and get the full path from databases json file
// and error if database does not exist
def db_map = [
  "nt":"/mnt/efs/databases/Blast/nt/db/nt",
  "nr":"/mnt/efs/databases/Blast/nr/db/nr",
  "ncbi_16s":"/mnt/efs/databases/Blast/16S_ribosomal_RNA/db/16S_ribosomal_RNA",
  "silva":"/mnt/efs/databases/Blast/Silva/v138.1/silva138",
  "silva_nr":"/mnt/efs/databases/Blast/Silva/v138.1/silva138_nr",
  "immeDB":"/mnt/efs/databases/Blast/immeDB/db/immeDB",
]


def db_path = null

if (db_map[params.db]){
  db_path = db_map[params.db]
  log.info"""Using database at location ${db_path}""".stripIndent()
} else {
  log.info"""
    Cannot find the database specified by --db ${params.db}. Must use one of:
    """.stripIndent()
    db_map.each { key, value ->
    log.info "$key"
}
  exit 0
}

// Base path for all output files
basepath = params.outdir + "/" + params.project

if (params.seedfile == null){
  /* 
  * Given the query parameter creates a channel emitting the query fasta file(s), 
  * the file is split in chunks containing as many sequences as defined by the parameter 'chunksize'.
  * Finally assign the result channel to the variable 'fasta_ch' 
  */

  //Creates working dir
  workingpath = basepath + "/" + params.sample_name + "/" + params.db + "/" + params.prefix
  workingdir = file(workingpath)

  if( !workingdir.exists() ) {
      if( !workingdir.mkdirs() )     {
          exit 1, "Cannot create working directory: $workingpath"
      } 
  }    
  def out = "${workingpath}/${params.sample_name}.${params.blast_type}.tsv"

  /* 
  * Executes a BLAST job for each chunk emitted by the 'fasta_ch' channel 
  */

  Channel
    .fromPath(params.query)
    .ifEmpty { exit 1, "Cannot find matching fasta file" }
    .splitFasta(by: params.chunksize, file:true)
    .set { fasta_ch }

  process blast {
    cpus 2
    memory 8.GB

    input:
    path 'query.fa' from fasta_ch

    output:
    file 'blast_result' into hits_ch

    script:
    """
    ${params.blast_type} \
      -num_threads  $task.cpus \
      -query query.fa \
      -db $db_path \
      -dbsize ${params.dbsize} \
      -num_alignments ${params.max_aln} \
      -outfmt ${params.outfmt} > blast_result
    """
  }

 /* 
 * Collects all the sequences files into a single file 
 */ 
  hits_ch
      .collectFile(name: out)

} else{

  Channel
    .fromPath(params.seedfile)
    .ifEmpty { exit 1, "Cannot find any seed file matching: ${params.seedfile}." }
    .splitCsv(header: true, sep: ',')
    .map{ row -> tuple(row.sample_name, file(row.fasta_file)) }
    .set {  fasta_ch  }


  /* 
  * Executes a BLAST job for each row/file emitted by the 'fasta_ch' channel 
  */

  process seedfile_blast {
      cpus 2
      memory 8.GB

      publishDir "${basepath}/${name}/${params.db}/${params.prefix}", mode: 'copy', pattern: "*.tsv"

      input:
      tuple val(name), file(fasta_file) from fasta_ch

      output:
      path("${name}.${params.blast_type}.tsv")

      script:
      """
      ${params.blast_type} \
        -num_threads  $task.cpus \
        -query query.fa \
        -db $db_path \
        -dbsize ${params.dbsize} \
        -num_alignments ${params.max_aln} \
        -outfmt ${params.outfmt} > $name.${params.blast_type}.tsv
      """
  }
}

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
 