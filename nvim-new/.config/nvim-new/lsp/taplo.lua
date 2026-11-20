-- TOML (Cargo.toml, pyproject.toml, yazi.toml, ...).
return {
	cmd = { "taplo", "lsp", "stdio" },
	filetypes = { "toml" },
	root_markers = { ".taplo.toml", "taplo.toml", ".git" },
}
