-- YAML (docker-compose, GitHub Actions, configs).
return {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose" },
	root_markers = { ".git" },
	settings = {
		redhat = { telemetry = { enabled = false } }, -- don't send usage data
	},
}
