-- Auto-download subs on file load if none present
local utils = require("mp.utils")
local msg = require("mp.msg")

local SUBGET = os.getenv("HOME") .. "/.local/bin/subget"

local function has_subs()
	for _, t in ipairs(mp.get_property_native("track-list")) do
		if t.type == "sub" then
			return true
		end
	end
	return false
end

local function fetch()
	local path = mp.get_property("path", "")
	if not path:match("^/") then
		return
	end -- skip streams
	if has_subs() then
		msg.info("subs already present")
		return
	end
	msg.info("fetching subs via subget")
	local res = utils.subprocess({ args = { SUBGET, path }, cancellable = false })
	msg.info(res.stdout)
	if res.status ~= 0 then
		msg.warn("subget failed: " .. (res.stderr or ""))
		return
	end
	-- rescan folder so mpv picks up the new .srt
	mp.commandv("rescan-external-files", "reselect")
end

mp.register_event("file-loaded", fetch)
mp.add_key_binding("b", "fetch_subs", fetch)
