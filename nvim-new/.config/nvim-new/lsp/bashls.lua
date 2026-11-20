-- Bash / sh scripts (uses shellcheck for warnings).
return {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash" },
    root_markers = { ".git" },
}
