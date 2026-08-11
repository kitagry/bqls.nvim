local M = {}

--- Parses a semver-ish string ("v1.2.3" or "1.2.3") into { major, minor, patch }.
---@param version string
---@return integer[]|nil
local function parse(version)
	local major, minor, patch = version:match("^v?(%d+)%.(%d+)%.(%d+)")
	if not major then
		return nil
	end
	return { tonumber(major), tonumber(minor), tonumber(patch) }
end

--- Numerically compares two semver strings, tolerating an optional "v" prefix.
--- A plain string comparison would misorder e.g. "v0.10.0" before "v0.9.0".
---@param a string
---@param b string
---@return integer|nil -1 if a<b, 0 if a==b, 1 if a>b, or nil if either is unparseable
function M.compare(a, b)
	local pa = parse(a)
	local pb = parse(b)
	if not pa or not pb then
		return nil
	end
	for i = 1, 3 do
		if pa[i] ~= pb[i] then
			return pa[i] < pb[i] and -1 or 1
		end
	end
	return 0
end

--- Returns true if `version` is strictly older than `min_version`.
--- Unparseable versions are treated as not-older (fail open, since we don't
--- want a warning misfiring on a version string we don't understand).
---@param version string
---@param min_version string
---@return boolean
function M.is_older_than(version, min_version)
	local cmp = M.compare(version, min_version)
	return cmp ~= nil and cmp < 0
end

return M
