extends Node

@export var registered_sites: Array[WebsitePage] = []
# Se quiser um 403 padrão, exporte aqui:
@export var error_403_page: WebsitePage 

# A mágica da limpeza:
func _sanitize_url(raw_url: String) -> String:
	var clean_url = raw_url.to_lower().strip_edges()
	clean_url = clean_url.trim_prefix("https://")
	clean_url = clean_url.trim_prefix("http://")
	clean_url = clean_url.trim_prefix("www.")
	return clean_url

# A busca real que o Browser vai chamar:
func fetch_page(url: String) -> WebsitePage:
	var target_url = _sanitize_url(url)
	
	for site in registered_sites:
		if _sanitize_url(site.url) == target_url:
			return site
			
	# Se não achou nada, devolve o 403 ou nulo
	if error_403_page:
		return error_403_page
	return null