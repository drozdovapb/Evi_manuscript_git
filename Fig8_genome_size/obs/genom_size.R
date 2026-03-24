library(ggplot2)
library(openxlsx)
library(ggpubr)
library(svglite)
install.packages("svglite")

## read data
Evidat <- read.xlsx("Evi_genomsize.xlsx")
## check format
str(Evidat)
hist(Evidat$pg)

## QC
Evidat <- Evidat[Evidat$RCS < 4 & Evidat$a_CV < 0.1 & Evidat$b_CV < 0.1, ]

## Mann-Whitney test
pairwise.wilcox.test(Evidat$pg, Evidat$Population)


## Plotting
Evidat$Population <- factor(Evidat$Population, levels = c("S", "W"))

ggplot(data = Evidat, 
       aes(x = Population, y = pg)) + 
  expand_limits(y = c(0, 8)) +
  geom_boxplot(aes(col = Population), outlier.color = 'NA', show.legend = F) + 
  geom_jitter(aes(col = Population), show.legend = F) + 
  scale_color_manual(values = c("#4477AA", "#F0E442")) +
  xlab("Haplogroup") + ylab("Genome size, pg") + 
  theme_bw(base_size = 16)

ggsave("FCM.svg", width = 4.5, height = 7)
