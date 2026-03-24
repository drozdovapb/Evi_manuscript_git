#Creating a database for local BLAST (for linux)
system("makeblastdb -dbtype nucl -in model_seq_Eulimno.fa -input_type fasta -parse_seqids -out model_seq_Eulimno.blastdb")
#Loading packages
library(rBLAST)
library(tidyr)
#Specify the path to the database BLAST
custom_db_path <- blast(db = "0_model_seq_Eulimno.blastdb")
#We pass the .fasta file to the variable
seq <- readDNAStringSet("0_Eulimno_COI_wref.fasta")
#Test command to run rBLAST
cl <- predict(custom_db_path, seq[600, ], BLAST_args = "-perc_identity 95") #Compares sequence number 600 from the .fasta file and searches the database for a sequence with a percent identity of at least 95
#Estimated length of .fasta file (how many sequences in total)
length(seq)
#A command that creates a BLAST result sheet for all sequences in a .fasta file.
a <- lapply(1:length(seq), function(x) predict(custom_db_path, seq[x, ], BLAST_args = "-perc_identity 95"))
#Creates a shared dataframe containing all BLAST results.
df <- tibble(data = a) %>%
  unnest_wider(data) %>%
  unnest(qseqid)
#Delete all columns except the first two.
df <- df[ , c(13,14)]
#Create a vector from the sequence IDs of your .fasta file
current_names <- names(seq)
#Create new sequence headers for the .fasta file
new_headers <- paste(
  current_names, 
  "_", df$sseqid, # Append new data
  sep = "" # Or use a separator like "_", "|"
)
#Assign new headers to your .fasta file
names(seq) <- new_headers
#And also remove spaces from names because they spoil everything!!
names(seq) <- sub(" ", "_", names(seq))
#Save the new .fasta file
writeXStringSet(seq, "1_Eulimno_COI_wref_with_class.fasta", format="fasta")
#Clean up
system("rm *.blastdb*")
