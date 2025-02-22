library(rvest)
library(tidyverse)
library(here)
library(lubridate)
library(feather)


# carregar p�gina com a listagem e os links de todos os setores do mercado

read_primato_set <- read_html(
  paste(
    "https://supermercado.primato.com.br/loja/departamentos/", sep = ""
  ))


# preparar vetor

setores <- c()


# extrair href dos setores
get_setores <- read_primato_set%>%
  html_nodes(".h4,h4 a")%>%
  html_attr("href")


setores <- append(setores, get_setores)


# transformar hrefs em urls

link_setores <- data.frame( set_link = paste(
  "https://supermercado.primato.com.br", setores, "/?page=", sep = ""
)
)


# fun��o para descobrir a quantidade de paginas em cada setor,
# n�o encontrei solu��o que n�o envolve loop porque � necessario testar
# cada uma das paginas at� "proximo" n�o aparecer no html

num_page <- function(url_set){
  
  #define pagina inicial
  
  i <- 1
  
  
  # l� url da pagina inicial
  
  read_primato <- read_html(
    paste(
      url_set, i, sep = "")
  )
  
  
  # checa a existencia dos bot�es de navega��o
  
  t <- read_primato %>%
    html_nodes(".btn-sm")%>%
    html_text(trim = T)
  
  
  # prepara vetor para output
  
  urls <- c()
  
  
  # l� url, espera 0 a 3 segundos, checa se h� "proxima",
  # registra o link usado na lista e repete at� pagina final
  
  while(t[1] == "Pr�xima"){
    
    read_primato <- read_html(
      paste(
        url_set, i, sep = "")
    )
    
    Sys.sleep(sample(0:3))
    
    t <- read_primato %>%
      html_nodes(".btn-sm")%>%
      html_text(trim = T)
    
    link <- str_c(url_set, i, sep = "")
    
    urls <- append(urls, link)
    
    
    i <- i+1
  }
  
  # retorna a lista de urls acumuladas no loop
  
  return(urls)
}



get_pages <- purrr::map(link_setores[1:34,], num_page)


df <- purrr::map_dfr(get_pages, as.data.frame)

write_feather(df, path = paste(here(), "/urls.feather", sep = ""))





