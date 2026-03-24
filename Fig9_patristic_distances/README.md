## Analysis pipeline for Fig. 9 (split networks and patristic distances)
Idea of the analysis: compare four studied _Eulimnogammarus_ species adequately (the same COI fragment) => correlate the differences with presence/absence of hybridization observed in the nature and/or in the laboratory.

### Steps:

  - Compiled a multifasta file of all sequences (`1_BLAST_append_names/Eulimno_COI.fasta`) and classification file (`1_BLAST_append_names/model_seq_Eulimno.fa`).
  - Added lineage letter with `1_BLAST_append_names/Script_new_ID_for_fasta.R`:
    ```{bash}
    cd ./1_BLAST/
    Rscript ./Script_new_ID_for_fasta.R
    cp Eulimno_COI_with_class.fasta ../0_Eulimno_COI_with_class.fasta 
    ```
  - Alignment: mafft in UGENE => manually trimmed to the coordinates of P. monodon COI 100-580 AF217843 (484-bp alignment)

    # split sequences into files for each species
    `~/lib/kentUtils/faFilter -name=*verrucosus* 2_Eulimno_COI_wref_aln.trim.fa 3_Eve.fasta`
    `~/lib/kentUtils/faFilter -name=*cyaneus* 2_Eulimno_COI_wref_aln.trim.fa 3_Ecy.fasta`
    `~/lib/kentUtils/faFilter -name=*vittatus* 2_Eulimno_COI_wref_aln.trim.fa 3_Evi.fasta`
    `~/lib/kentUtils/faFilter -name=*marituji* 2_Eulimno_COI_wref_aln.trim.fa 3_Ema.fasta`

    # statistics on the # of sequences
    grep -c \> 3_*fasta
    #4_Ecy.fasta:160
    #4_Ema.fasta:63 ## had to remove 2 sequences manually; were not long enough
    #4_Eve.fasta:375 ## had to remove 2 sequences manually; were not long enough
    #4_Evi.fasta:141 ## had to remove 7 sequences manually; were not long enough

    ```
  - Then loaded each alignment (`3_E*.fasta`) into SplitsTree4 and saved to nexus with splits (File => Save As).
  - Nexus files (`3_SplitsTree/`) were loaded into `Fig9_draw_network_maps.R` to plot split networks to the same scale (Fig. 9A).
  - The same alignments (`3_E*.fasta`) were used to calculate distances:
    - p and K2P distances with MEGA11 (see screenshot in the `3_mega` folder for an example)
    - patristic distances were calculated by first reconstructing the tree in IQ-TREE2 and then getting the matrix of distances from the Patristic software. The resulting files were edited to remove excessive commas at the end of each line (see screenshot in `3_iqtree_patristic` for details). (`grep ',$' eve.patristic.csv` and sed didn't work for some reason.)
    ```{bash}
    iqtree2 -s ../2_alignment/3_Ecy.fasta -m GTR+I+G --prefix ecy
    iqtree2 -s ../2_alignment/3_Ema.fasta -m GTR+I+G --prefix ema
    iqtree2 -s ../2_alignment/3_Eve.fasta -m GTR+I+G --prefix eve
    iqtree2 -s ../2_alignment/3_Evi.fasta -m GTR+I+G --prefix evi
    java -jar ~/lib/Patristic/Patristic.jar
    # clean up
    rm *log; rm *mldist; rm *bionj; rm *uniqueseq.phy; rm *ckp.gz # rm *model.gz; not needed
    ```
  - These distances were loaded into `Fig9_draw_network_maps.R` to produce plots in Fig. 9B. It also produces statistics in plain text (rearranged manually, see `statistics.csv`).

### Software used:
  - R packages:
     - phangorn ## required for tanggle to read networks
     - tanggle ## plot networks
     - ggtree ## required by tanggle
     - ape ## required by tanggle
     - dplyr ## for table rearrangement
     - ggplot2 
     - cowplot ## to combine plots
     - ggrastr ## to rasterize points and reduce svg size!
     - reshape2 ## for melt
     - matrixcalc #triangular matrix for lower.triangle
     - rBLAST ## for appending suffixes
     - tidyr ## for data manipulation
  - ncbi-blast+ 2.12.0+
  - kentUtils
  - MAFFT v7.490 (2021/Oct/30)
  - IQ-TREE 2.0.7
  - Patristic
  - UGENE v44
  - MEGA11
