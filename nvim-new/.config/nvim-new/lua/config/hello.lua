local M = {}
M.name = "nvim-new"
function M.say(word)
	print(word .. " from " .. M.name)
end
return M
