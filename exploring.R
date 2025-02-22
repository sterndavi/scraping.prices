library(tidyverse)
library(here)
library(glue)
library(DataExplorer)



df0712 <- feather::read_feather(
  path = glue("{here()}/data/precos 2021-12-07.feather"))
df0812 <- feather::read_feather(
  path = glue("{here()}/data/precos 2021-12-08.feather"))
df0912 <- feather::read_feather(
  path = glue("{here()}/data/precos 2021-12-09.feather"))
df1012 <- feather::read_feather(
  path = glue("{here()}/data/precos 2021-12-10.feather"))
df1112 <- feather::read_feather(
  path = glue("{here()}/data/precos 2021-12-11.feather"))
df1212 <- feather::read_feather(
    path = glue("{here()}/data/precos 2021-12-12.feather"))
df1312 <- feather::read_feather(
  path = glue("{here()}/data/precos 2021-12-13.feather"))
df1412 <- feather::read_feather(
    path = glue("{here()}/data/precos 2021-12-14.feather"))
df1512 <- feather::read_feather(
    path = glue("{here()}/data/precos 2021-12-1.feather"))

df0712 <- df0712 %>% 
  left_join(df1312, by = "mercadorias") %>%
  select(timestamp.x, setores, mercadorias, precos.x)%>%
  rename("timestamp" = timestamp.x, "precos" = precos.x)

df0812 <- df0812 %>% 
  left_join(df1312, by = "mercadorias") %>%
  select(timestamp.x, setores, mercadorias, precos.x)%>%
  rename("timestamp" = timestamp.x, "precos" = precos.x)

df0912 <- df0912 %>% 
  left_join(df1312, by = "mercadorias") %>%
  select(timestamp.x, setores, mercadorias, precos.x)%>%
  rename("timestamp" = timestamp.x, "precos" = precos.x)


df <- df0712 %>% 
  add_row(df0812) %>% 
  add_row(df0912) %>% 
  add_row(df1012) %>% 
  add_row(df1112) %>% 
  add_row(df1212) %>%
  add_row(df1312) %>%   
  add_row(df1412) %>%
  add_row(df1512)
    
    
DataExplorer::create_report(df)

df %>%
    group_by(timestamp, setores, mercadorias) %>% 
    filter(setores == "acougue") %>% 
    view()
    


