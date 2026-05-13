extends Node

@export var registered_sites: Array[WebsitePage] = []

# Busca a URL no banco de dados com Sanitização de String (UX Friendly)
func resolve_url(target_url: String) -> WebsitePage:
	# 1. Limpa o que o jogador digitou (joga tudo pra minúsculo e arranca o www.)
	var clean_target: String = target_url.to_lower().trim_prefix("www.")
	
	for site in registered_sites:
		if site != null:
			# 2. Limpa o que o Game Designer cadastrou no .tres (pelo mesmo motivo)
			var clean_site_url: String = site.url.to_lower().trim_prefix("www.")
			
			# 3. Compara as versões limpas
			if clean_site_url == clean_target:
				return site
				
	return null
