-- Javascript + Typescript (also .jsx / .tsx).
return {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_markers = { "package.json", "tsconfig.json", "jsonconfig.json", ".git" },
    init_options = { provideFormatter = true },
}

