#!/bin/bash
#SBATCH --job-name=leopard_mitochondrial_DNA
#SBATCH --partition=epyc
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=5-00:00:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --mail-user=sullivan-al-kadhomiyj@cardiff.ac.uk
#SBATCH --mail-type=END,FAIL

################################## VARIABLE CREATION #######################################

WORK_DIR=$(pwd)
NOVO_DIR="/mnt/scratch45/c1904322/apps/NOVOPlasty/NOVOPlasty"
OUT_DIR="$WORK_DIR/NOVO_outputs"
SEED="$WORKDIR/references/penguin_COI_seed.fasta"
READ_DIR="$WORK_DIR/reads"
REF_DIR="$WORK_DIR/references/leopard_mito_reference.fasta.txt"

################################### PREPARATION ###########################################

module load perl                                                         # for running NOVOPlasty

shopt -s nullglob                                                        # Enable the nullglob option to stop loops running if nothing in the nullglob (*) is found.

######################## CREATING CONFIG FILES FOR EACH SAMPLE ############################

for R1 in ${READ_DIR}/*_1.fq *_R1.fq *_R1.fastq.gz                       # A loop for all R1 fq files
do
    SAMPLE=$(basename "$R1" | sed 's/_R1.*//; s/_1.*//')                 # remove the filepath from R1, then replace (s/) x/ with y/. In this case y/ is nothing. Creates a variable for the sample name
    R2=$(echo "$R1" | sed 's/_R1/_R2/; s/_1/_2/')                        # Create R2 basenames using the same principle.

    if [ ! -f "$R2" ]; then
        echo "Missing R2 for $R1 — skipping"                             # If the R2 counterpart for R1 is missing then skip this file and continue
        continue
    fi

    echo "=== Running sample: $SAMPLE ==="                               # State which sample is running

    SAMPLE_OUT="$OUT_DIR/$SAMPLE"                                        # Creating a variable to create a directory for each sample in the output directory
    mkdir -p "$SAMPLE_OUT"                                               # If the sample folder is not there already then make it

    CONFIG="$SAMPLE_OUT/config_${SAMPLE}.txt"                            # Stating how and where the config files should be saved and named

    cat > "$CONFIG" <<EOF                                                 # take everything below and write it into a file
Project:
-----------------------
Project name          = $SAMPLE                                           # name for the run
Type                  = mito                                              # mitochondrail instead of chloroplast
Genome Range          = 12000-22000                                       # for mammalian genomes (roughly)
K-mer                 = 39                                                # recommended for 250bp read length
Max memory            =                                                   # usually balnk. NOVOPlasty automatically manages memory
Extended log          = 0                                                 # 0=normal logs. 1=very detailed logs.
Save assembled reads  = no                                                # usually unnecessary for novoplasty to save all the reads used in the assembly
Seed Input            = $SEED                                             # starting sequence for the assembly
Reference sequence    = #$REF_DIR                                         # This provides a complete mitochondrial genome reference to guide the assembly.
Variance detection    =                                                   # Detects sequence variants (mutations) relative to a reference genome. This is for variant calling, not just assembly. When you want to detect mitochondrial polymorphisms. Yes or no.
Chloroplast sequence  =                                                   # This is for plant dataases.

Dataset 1:
-----------------------
Read Length           = 150                                               # length of the sequencing reads
Insert size           = 300                                               # distance between paired reads
Platform              = illumina                                          # which sequencing technology produces the reads
Single/Paired         = PE                                                # paired-ends
Combined reads        =                                                   # Used if your sequencing data is not separated into R1 and R2 files.
Forward reads         = $WORK_DIR/$R1                                     # location of forward read files
Reverse reads         = $WORK_DIR/$R2                                     # location of reverse read files

Optional:
-----------------------
Insert size auto      = yes                                               # NOVOPlasty estimates fragment size. safe to leave it on
Use Quality Scores    = yes                                               # Uses FASTQ quality scores during assembly. Recommended

Output path           = $SAMPLE_OUT                                       # where to save the output
EOF                                                                       # closing EOF for text reading

##################################### RUNNING NOVOPLASTY #####################################

    perl "$NOVO_DIR/NOVOPlasty.pl" -c "$CONFIG"                           # running the NOVOPlasty pipeline using the created config files.

done

echo "=== NOVOPlasty batch complete ==="

module purge
