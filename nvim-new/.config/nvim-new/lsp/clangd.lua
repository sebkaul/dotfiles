-- C / C++ (from the `clang` package). Reads compile_commands.json if present.
return {
	cmd = { "clangd" },
	filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
	root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", ".git" },
}
