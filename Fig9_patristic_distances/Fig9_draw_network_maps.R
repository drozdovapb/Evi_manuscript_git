## Packages used
## for networks (first row of panels)
library(phangorn) ## required for tanggle to read networks
library(tanggle) ## plot networks
library(dplyr) ## for table rearrangement
#library(ggpubr) ## to combine plots
library(cowplot) ## kinda works better to combine plots
library(ggrastr) ## to rasterize points and reduce svg size!
## for diversity metrics (second row of panels)
library(reshape2) ## for melt
library(matrixcalc) #triangular matrix for lower.triangle

## a function to plot default split networks
draw.split.network <- function(Nnet) {
  ## read split network from nexus file
  ## and rotate to the necessary angle
  pn <- ggsplitnet(Nnet)
  ## get the table with tip labels and positions
  tips <- pn$data[pn$data$isTip, ]
  ## extract species names from labels as 4 last letters
  tips$species <- substr(tips$label, start = nchar(tips$label)-3, stop = nchar(tips$label))
  ## reformat for plotting
  tips %>% count(x, y, species) -> tips.occur
  ## initial plot
  p <- ggsplitnet(Nnet, color="grey20", linewidth=0.2) +
    ## get fixed x:y ratio
    coord_fixed() + 
    ## add points
    geom_point(data=tips.occur, aes(x=x, y=y, fill=species), shape=21, size=2, stroke = .1) + 
    ## species names in italics and in the center
    theme(plot.title = element_text(face = "italic", hjust = 0.5), 
          legend.position = "none") ## remove legend, it doesn't really help much
  ## rasterize points and lines (!!) to make size smaller
  p <- rasterize(input = p, layers = c("Point", "Segment"), dpi = 600)
    return(p)
}

## read the data = nexus file recorded by SpitsTree4
Nnet.ecy <- read.nexus.networx("3_SplitsTree/5_Ecy.fasta.nex")
Nnet.eve <- read.nexus.networx("3_SplitsTree/5_Eve.fasta.nex")
Nnet.evi <- read.nexus.networx("3_SplitsTree/5_Evi.fasta.nex")
Nnet.ema <- read.nexus.networx("3_SplitsTree/5_Ema.fasta.nex")

## first, draw initial plots with correct colors and titles
## (but each to its own scale)

pcy <- draw.split.network(Nnet.ecy) + 
  ggtitle("E. cyaneus") + 
  scale_fill_manual(values = "cyan")
pcy

pma <- draw.split.network(Nnet.ema) + 
  ggtitle("E. marituji") + 
  scale_fill_manual(values = c("mediumpurple3", "#4477AA" ,"#F0E442"))
pma

pvi <- draw.split.network(Nnet.evi) + 
  ggtitle("E. vittatus") + 
  scale_fill_manual(values = c("#f6850c", "#4477AA", "#F0E442"))
pvi

pve <- draw.split.network(Nnet.eve) + 
  ggtitle("E. verrucosus") + 
  scale_fill_manual(values = c("#D81B60", "#4477AA", "#F0E442"))
pve

## small functions to get plot parameters for further adjustments
## width and height
get.width <- function(this.plot) {
  return(layer_scales(this.plot)$x$get_limits()[2] - layer_scales(this.plot)$x$get_limits()[1])
}

get.height <- function(this.plot) {
  return(layer_scales(this.plot)$y$get_limits()[2] - layer_scales(this.plot)$y$get_limits()[1])
}

## horizontal middle of the plot for scale bar placement
get.avgx <- function(this.plot) {
  max.x <- layer_scales(this.plot)$x$get_limits()[2]
  min.x <- layer_scales(this.plot)$x$get_limits()[1]
  avg.x <- mean(c(min.x, max.x))
  return(avg.x)}

## vertical center of the plot for title / scale bar
get.avgy <- function(this.plot) {
  max.y <- layer_scales(this.plot)$y$get_limits()[2]
  min.y <- layer_scales(this.plot)$y$get_limits()[1]
  avg.y <- mean(c(min.y, max.y))
  return(avg.y)}

## get the largest width and height to update all plots to have the same area
## and also adding scale bar here
ourwidth <- max(get.width(pve), get.width(pvi), get.width(pma), get.width(pcy))
ourheight <- max(get.height(pve), get.height(pvi), get.height(pma), get.height(pcy))

## function to update plot limits
update_limits <- function(this.plot) {
  this.plot <- this.plot + 
    xlim(get.avgx(this.plot)-ourwidth/2, get.avgx(this.plot)+ourwidth/2) + 
    ylim(get.avgy(this.plot)-ourheight/2, get.avgy(this.plot)+ourheight/2) 
  this.plot + geom_treescale(offset = 0.002, width = 0.01, 
                             x = get.avgx(this.plot), y=get.avgy(this.plot)-ourheight/2)
}

## apply function and update plot limits
pcy2 <- update_limits(pcy)
pma2 <- update_limits(pma)
pvi2 <- update_limits(pvi)
pve2 <- update_limits(pve)

## combine plots with proper margins => equal scales
pnetworks <- plot_grid(pcy2, pma2, pvi2, pve2, nrow = 1) ##labels=LETTERS[1:4]
## take a look at the result
pnetworks
## write to file (mainly for testing)
#ggsave(filename = "networks_to_scale.png",  
#       device=png, width=20, height=12, units="in", dpi = 300, bg = "white")
#ggsave(filename = "networks_to_scale.svg",  
#       device=svg, width=20, height=12, units="in", bg = "white")


## Part 2
## Metrics of diversity within species

## generic function to plot any distance from csv file
plot_distances <- function(csv_filename, already_triangular=TRUE) {
  ## read matrix and make it triangular
  table <- read.csv(csv_filename, row.names = 1)
  if(already_triangular==FALSE) table <- lower.triangle(as.matrix(table))
  print(max(table))
  ## put  back zeroes
  table[is.na(table)] <- 0
  table <- as.matrix(table)
  ## print max value for information
  print(max(table))
  ## melt to long format
  table_long <- melt(table)
  ## retain only meaningful values (no self-comparisons)
  table_long <- table_long[table_long$value > 0, ]
  ## get first and second letters
  table_long$first <- unlist(sapply(strsplit(x = as.character(table_long$Var1), split = "_"), FUN = function(x) {x[length(x)]}))
  table_long$second <- unlist(sapply(strsplit(x = as.character(table_long$Var2), split = "_"), FUN = function(x) {x[length(x)]}))
  ## group = biological species
  ## assembl labels for the x axis (two-line and SW == WS etc)
  table_long$group <- paste(substr(table_long$first, 4,4), substr(table_long$second,4,4), sep = "\n")
  table_long$group[table_long$group == "S\nW"] <- "W\nS"
  table_long$group[table_long$group == "E\nW"] <- "W\nE"
  table_long$group[table_long$group == "N\nW"] <- "W\nN"
  table_long$group[table_long$group == "N\nS"] <- "S\nN"
  table_long$group[table_long$group == "S\nE"] <- "E\nS"
  table_long$group[table_long$group == "S\nC"] <- "C\nS"
  ## let's make sure we don't run the same comparisons twice
  print(paste("number of comparisons", nrow(table_long))) 
  ## get statistics
  message(csv_filename)
  message("min values")
  print(tapply(table_long$value, table_long$group, min))
  message("median values")
  print(tapply(table_long$value, table_long$group, median))
  message("max values")
  print(tapply(table_long$value, table_long$group, max))
  ## now to plotting
  myplot <-   ggplot(table_long, aes(x=group, y=value)) +
    #geom_jitter(size=0.5, alpha=0.1) + ## optinal: points
    ## decided on violins
    ## area proportional to # of observations and width to make larger
    geom_violin(fill = "grey", scale = "count", width = 0.9) + ##maybe #, scale = "count") + 
    #geom_boxplot() + ## also boxplots possible
    expand_limits(y=c(0, 0.26)) + ## enforce equal limits
    scale_x_discrete(limits = rev) + ## reverse x scales (W, S, E, C)
    scale_y_continuous(n.breaks=6) + ## enforce y axis ticks
    xlab("") + ylab("") + ## get rid of useless axis labels
    theme_bw(base_size = 14) + ## bigger fonts
    theme(plot.title = element_text(hjust=0.5, size=14)) ## center title
  ## if using points need to rasterize to get adequate file size
  #myplot <- rasterize(myplot, layer = c("Jitter"), dpi=300)
  return(myplot)
}

## K2P distance (Kimura 2-parameter; calculated with MEGA)
## and p distance (uncorrected; calculated with MEGA)
## Ecy
k2pdist.cy <- plot_distances("3_mega/Ecy_K2P.txt") + ggtitle("K2P Ecy")
pdist.cy <- plot_distances("3_mega/Ecy_p.txt") + ggtitle("P Ecy")
## Ema
k2pdist.ma <- plot_distances("3_mega/Ema_K2P.txt") + ggtitle("K2P Ema")
pdist.ma <- plot_distances("3_mega/Ema_p.txt") + ggtitle("P Ema")
## Evi
k2pdist.vi <- plot_distances("3_mega/Evi_K2P.txt") + ggtitle("K2P Evi")
pdist.vi <- plot_distances("3_mega/Evi_p.txt") + ggtitle("P Evi")
## Eve
k2pdist.ve <- plot_distances("3_mega/Eve_K2P.txt") + ggtitle("K2P Eve")
pdist.ve <- plot_distances("3_mega/Eve_p.txt") + ggtitle("P Eve")

## patristic distances with iqtree, then patristic
## edited csv manually (see screenshot)
ecy.patrdist <- plot_distances("3_iqtree_patristic/ecy.patristic.ed.csv", already_triangular = FALSE) + 
  ggtitle("Ecy, Patristic ML") + geom_hline(yintercept = 0.16, linetype = "dotted")
ema.patrdist <- plot_distances("3_iqtree_patristic/ema.patristic.ed.csv", already_triangular = FALSE) + 
  ggtitle("Ema, Patristic ML") + geom_hline(yintercept = 0.16, linetype = "dotted")
evi.patrdist <- plot_distances("3_iqtree_patristic/evi.patristic.ed.csv", already_triangular = FALSE) + 
  ggtitle("Evi, Patristic ML") + geom_hline(yintercept = 0.16, linetype = "dotted")
eve.patrdist <- plot_distances("3_iqtree_patristic/eve.patristic.ed.csv", already_triangular = FALSE) + 
  ggtitle("Eve, Patristic ML") + geom_hline(yintercept = 0.16, linetype = "dotted")

## statistics for the text
ggplot_build(ecy.patrdist)$data[[1]]



## empty plot (we'll need it for later arrangement)
p.empty <- ggplot() + theme_minimal()

## arrange patristic distance plots
ppatr_scaled <- plot_grid(p.empty, ecy.patrdist + ggtitle(""), p.empty,
                          ema.patrdist + ggtitle(""), 
                          evi.patrdist + ggtitle(""), 
                          eve.patrdist + ggtitle(""), 
                          nrow=1, rel_widths = c(0.75, 1.5, 0.75, 3, 3, 3))
## take a look
ppatr_scaled


## combine with networks
plot_grid(pnetworks, ppatr_scaled, nrow=2, rel_heights = c(2, 1.2), labels = "AUTO")

## tried with ggarrange, no difference
#ggpubr::ggarrange(pnetworks, ppatr_scaled, nrow=2, 
#                  heights = c(2, 1.2), labels = "AUTO")

## and save Fig. 9
ggsave("Fig9_Eu_sp_networks_patristic.png", bg = "white",
       width=24, height=18, units="cm", res=600, device=png)
ggsave("Fig9_Eu_sp_networks_patristic.svg", bg = "white",
       width=24, height=18, units="cm", device=svg)

## and all distances for the supplementary
ppatr <- plot_grid(ecy.patrdist, ema.patrdist, evi.patrdist, eve.patrdist, 
                   rel_widths = c(0.5, 1, 1,1), nrow=1)
ppdist <- plot_grid(pdist.cy, pdist.ma, pdist.vi, pdist.ve, 
                    rel_widths = c(0.5, 1, 1,1), nrow=1)
pk2pdist <- plot_grid(k2pdist.cy, k2pdist.ma, k2pdist.vi, k2pdist.ve, 
                      rel_widths = c(0.5, 1, 1,1), nrow=1)
plot_grid(ppatr, ppdist, pk2pdist, nrow=3, labels="AUTO")
ggsave("FigSX_Eu_sp_distances.png", bg = "white",
       width=24, height=18, units="cm", res=600, device=png)

