## Packages

library(ggplot2)
library(openxlsx)
library(ggpubr)
library(svglite)

######## A. Genome size

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

pFCM <- ggplot(data = Evidat, 
       aes(x = Population, y = pg)) + 
  expand_limits(y = c(0, 8)) +
  geom_boxplot(aes(col = Population), outlier.color = 'NA', show.legend = F) + 
  geom_jitter(aes(col = Population), show.legend = F) + 
  scale_color_manual(values = c("#4477AA", "#F0E442")) +
  xlab("Haplogroup") + ylab("Genome size, pg") + 
  theme_bw(base_size = 14)

pFCM
#ggsave("FCM.svg", width = 4.5, height = 7)


########### B. Body length

## read data
Evidat <- read.xlsx("Evi_lengths.xlsx")
## check format
str(Evidat)
hist(Evidat$Length)

## Mann-Whitney test
Evidat$Population <- substr(Evidat$Species, 4, 4)
pairwise.wilcox.test(Evidat$Length, Evidat$Species)

## Plotting
Evidat$Population <- factor(Evidat$Population, levels = c("S", "W"))

ggplot(data = Evidat, 
       aes(x = Population, y = Length, col = Population, shape=Sex)) + 
  geom_boxplot(outlier.color = 'NA') + 
  expand_limits(y=c(0, 25)) + 
  geom_jitter(position=position_jitterdodge(jitter.width=0.3), aes(group=Sex)) + 
  scale_color_manual(values = c("#4477AA", "#F0E442")) +
  xlab("Haplogroup") + ylab("Length, mm") + 
  theme_bw(base_size = 14) -> p1


Evidat %>% #filter(!is.na(Length)) %>%
  group_by(Population) %>% 
  wilcox_test(Length ~ Sex) %>% 
  adjust_pvalue(method="holm") %>%
  add_significance("p.adj") %>%
  add_xy_position(x = "Population", dodge = 0.8) -> stat.test1 

stat.test1$y.position <- rev(stat.test1$y.position)


p1 + stat_pvalue_manual(
  stat.test1,  label = "p.adj.signif", tip.length = 0) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) -> pBodyLength 

## there is no p.adjust and p = 0.65, so no point in adding a layer to the plot
Evidat %>% 
  wilcox_test(Length ~ Population, p.adjust.method = "holm") %>% 
  add_xy_position(x = "Population") -> stat.test2

pBodyLength

#ggsave("Length.svg", width = 6, height = 5, device = svg)
#ggsave("Length.png", width = 6, height = 5, device = png)


pairwise.wilcox.test(Evidat$Length, Evidat$Species)
pairwise.wilcox.test(Evidat$Length, Evidat$Sex)

summary(glm(data = Evidat, formula = Length ~ Species * Sex))

#### A+B combine plots


