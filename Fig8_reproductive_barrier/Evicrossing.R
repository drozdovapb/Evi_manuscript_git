library(openxlsx)
library(ggplot2)

## Prezygotic

mate.choice.tbl <- read.xlsx("mating Evi.xlsx")

mate.choice.tbl$Result <- factor(mate.choice.tbl$Result, levels = c("ND", "TRUE"))

ggplot(mate.choice.tbl) + geom_bar(aes(x = Type, fill = Result), position = "stack") + 
  coord_flip() + 
  scale_fill_manual(values = c("#CDC9C9", "#4EEE94")) +
  theme_bw(base_size = 14) + theme(panel.grid.minor.x = element_blank())
#ggsave("mate_choice_draft.png")
ggsave("mate_choice_draft.svg")

## Postzygotic
Sys.setlocale("LC_TIME", "C")
library(ggplot2)
library(openxlsx)
library(scales) ## for different linetypes
library(ggpubr) ## for ggarrange

## setting up plot
## colors
WxW <- "#F0E442"
WxS <- "#228833"
SxW <- "#66CCEE"
colcolors <- c(SxW, WxS, WxW)

## general plot settings
mytheme <- function(){
  list(theme_bw(base_size = 12), 
       theme(line = element_line(size = .5, color = "lightgrey"), 
             panel.grid.major.y = element_blank(),
             legend.position = 'NA', 
             strip.text = element_text(size=14)),
       #scale_fill_manual(values = fillcolors),
       scale_color_manual(values = colcolors),
       scale_y_continuous(breaks = pretty_breaks()),
       scale_linetype_manual(values = c("twodash", "dashed", "solid")), 
       scale_x_date(date_breaks = "1 month", date_labels = "%b"),
       theme(legend.position = 'bottom', legend.key.width = unit(1, "cm")))
}


facet.labels <- c("♀W × ♂W", "♀W × ♂ S", "♀S × ♂W")
names(facet.labels) <- c("WxW", "WxS", "SxW")

expdat <- read.xlsx("Crossing Evi.xlsx")
expdat$Date <- convertToDate(expdat$Date)

pfem <- 
  ggplot(expdat, aes(x = Date, col = Cross)) + 
  geom_line(aes(y = `Females.w/eggs`, linetype = Cross), size = 1) + 
  ylab("Ovigerous females") + 
  expand_limits(y=c(0, 6)) + 
  theme_bw(base_size = 14) + 
  mytheme()
pfem

pampl <- 
  ggplot(expdat, aes(x = Date, col = Cross)) + 
  geom_line(aes(y = `Amplexuses`, linetype = Cross), size = 1) + 
  expand_limits(y=c(0, 6)) + 
  mytheme()
pampl


pjuv <- 
  ggplot(expdat, aes(x = Date, col = Cross)) + 
  geom_line(aes(y = Juveniles, linetype = Cross), size = 1) +
  expand_limits(y=c(0, 6)) + 
  mytheme()
#ggsave("juv.svg", pjuv, width = 5, heigh = 3)
pjuv


pani <- 
  ggplot(expdat, aes(x = Date, col = Cross)) + 
  geom_line(aes(y = `Total.animals`, linetype = Cross), size = 1) + 
  expand_limits(y=c(0, 12)) + 
    ylab("Total animals") + 
  mytheme()
pani

library(extrafont)
font_import()
ggarrange(pani+rremove("x.axis"), pampl+rremove("x.axis"), pjuv, pani, 
          labels = LETTERS[4:7], 
          common.legend = TRUE, legend = "bottom")

ggsave("Evi_cross.png", width=9, height=5, device=png, bg = "white")
ggsave("Evi_cross.svg", width=9, height=5, device=svg())
