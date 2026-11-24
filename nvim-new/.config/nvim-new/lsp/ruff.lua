-- Python linter (unused imports, bug patterns, style), as a language server.
-- Runs next to pyright: pyright checks types, ruff checks everything else.
return {
    cmd = { "ruff", "server" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
}
