# Additional 2023 stock endpoint, using the same block-level replication.
# Six stock contrasts form a separate Holm family from the earlier 12 increment contrasts.
options(poplar.paper.root=getwd())
source('library.R')
x <- subset(read.csv('data/processed/tree_growth.csv'), measurement_year==2023)
stock_rows <- x |> dplyr::group_by(block,tree_row,hybrid) |>
 dplyr::summarise(n=sum(is.finite(carbon_stock_mg_ha)),stock=mean(carbon_stock_mg_ha,na.rm=TRUE),.groups='drop')
stopifnot(nrow(stock_rows)==36,all(stock_rows$n %in% 4:5),sum(stock_rows$n)==179)
b <- stock_rows |> dplyr::group_by(block,hybrid) |> dplyr::summarise(stock=mean(stock),.groups='drop')
b$block<-factor(b$block)
m <- lm(stock~block+hybrid,b)
a <- as.data.frame(anova(m));a$term<-rownames(a)
z <- as.data.frame(summary(pairs(emmeans::emmeans(m,~hybrid)),infer=c(TRUE,TRUE),adjust='none'))
z$p_holm_6<-p.adjust(z$p.value,'holm')
write.csv(stock_rows,'results/tables/growth_2023_stock_row_means.csv',row.names=FALSE)
write.csv(b,'results/tables/growth_2023_stock_block_means.csv',row.names=FALSE)
write.csv(a,'results/tables/growth_2023_stock_tests.csv',row.names=FALSE)
write.csv(z,'results/tables/growth_2023_stock_contrasts.csv',row.names=FALSE)
# Sensitivity with nine rows as paired units.
stock_rows$row_id<-factor(stock_rows$tree_row)
s<-lm(stock~row_id+hybrid,stock_rows)
y<-as.data.frame(summary(pairs(emmeans::emmeans(s,~hybrid)),infer=c(TRUE,TRUE),adjust='none'))
y$p_holm_6<-p.adjust(y$p.value,'holm')
write.csv(y,'results/tables/growth_2023_stock_row_sensitivity.csv',row.names=FALSE)
saveRDS(list(model=m,row_sensitivity=s,block_data=b,row_data=stock_rows),'results/models/growth_2023_stock_models.rds')
print(a);print(z);print(y)

# Always audit assumptions after fitting.
source('scripts/check_growth_2023_models.R')
