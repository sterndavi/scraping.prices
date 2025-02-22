{
library(rvest)
library(tidyverse)
library(here)
library(lubridate)
library(rio)
library(glue)
library(future)
library(furrr)
}

###############################################################


# l� arquivo com as urls

df1 <- feather::read_feather(path = paste(here(), "/urls.feather", sep = ""))


# Work in progress - preparando as variaveis categoricas
# ainda n�o adicionado ao resultado final

df1 <- df1 %>% 
  rename(urls = `.x[[i]]`)%>%
  mutate(setores = urls )%>%
  mutate(setores = str_remove_all(setores,regex("^(.*?)\\loja/"))) %>% 
  mutate(setores = str_replace_all(setores, "-", " "))%>%
  mutate(setores = str_remove_all(setores, regex("(?<=//).*")))%>%
  mutate(setores = str_remove_all(setores, regex("\\d"))) %>% 
  mutate(setores = str_remove_all(setores, " //"))


# fun��o que vai iterar url por url criando uma lista para pre�os e nomes

produtos <- function(urls,nome){
  loc <- c()
  merc <- c() # prepara vetor de mercadorias
  prec <- c() # prepara vetor de pre�os
  
  read_primato <- read_html(paste(urls)) # L� url da lista
  
  Sys.sleep(runif(1,0,0.5)) # espera um valor aleatorio entre 0 e 0,5 segundos
  
  mercadoria_pn <- read_primato %>% 
    html_nodes("a.link-nome-produto")%>%
    html_text(trim = T) # Puxa todos os nomes das mercadorias da pagina
  
  merc = append(merc, mercadoria_pn) # Adiciona os nomes no vetor
  
  preco_pn <- read_primato %>%
    html_nodes(".preco span") %>%
    html_text2() # Puxa todos os pre�os da pagina
  
  prec <- append(prec, preco_pn) # Adiciona os pre�os no vetor
  
  loc <- append(loc, nome)
  
  Sys.sleep(runif(1,0,0.5)) # Espera mais um tempo aleatorio entre 0 e 0,5
  
  return(tibble(loc,prec,merc))
}


# Chamar fun��o para cada linha da dataframe


# ////////////////////////////////////////TESTE MULTITHREADING

plan(multisession, workers = 4)

tictoc::tic()
get_prod <- future_map2_dfr(
  df1$urls,
  df1$setores,      #Insistetly() no lugar de safely() pra n�o gerar uma lista de error
  insistently(produtos,
              rate_delay(pause = 1, max_times = Inf)
              ),
  .options = furrr_options(seed = T) # 
)
tictoc::toc()


# ////////////////////////////////////////SINGLE THREADING



# ///// indeciso sobre usar future_map ou map normal, dependendo o computador parece que
#       o future map trava mas parece ser mais relacionado ao "insistently()",
#       tentar aumentar o num de requests



#get_prod <- map2_dfr(
#  df1$urls,
#  df1$setores,      #Insistetly() no lugar de safely() pra n�o gerar uma lista de error
#  insistently(produtos)
#)


future::

get_prods <- get_prod #troubleshoot step, antiga pipe que nao � usada mais

df_prods <- get_prods %>%
  rename(
    'mercadorias' = merc,
    'precos' = prec,     # Renomear as colunas
    'setores' = loc
  ) %>%
  mutate(
    "timestamp"  = lubridate::today() # Transformar os elementos de lista para caracteres
  )%>%      
  mutate(
    precos = str_replace_all(precos, ",", ".") # Substituir "," por "." nos pre�os
  )%>%
  mutate(
    precos = parse_double(precos) # Finalmente passar os pre�os de string para double
  )%>%         
  select(timestamp, setores, mercadorias, precos)


# Gerar summario simples

summ <- summary(df_prods)
diag <- dlookr::diagnose(df_prods)

# salva arquivo do dia

export(
  summ,
  file = glue(
    "{here()}/data/summary {today()}.csv"), format = "csv"
)#sumario estatistico

export(
  df_prods,
  file = glue(
    "{here()}/data/precos {today()}.feather"), format = "feather"
)#tabela completa com os resultados

export(
  diag, 
  file = glue(
    "{here()}/data/diag {today()}.csv"), format = "csv"
)#diagnostico das colunas

