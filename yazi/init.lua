-- ~/.config/yazi/init.lua
-- meloworld — yazi init
-- Custom linemode: size + mtime on the same line

function Linemode:size_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	local tstr
	if time == 0 then
		tstr = "         "
	elseif os.date("%Y", time) == os.date("%Y") then
		tstr = os.date("%b %d %H:%M", time)
	else
		tstr = os.date("%b %d  %Y ", time)
	end

	local size = self._file:size()
	local sstr = size and ya.readable_size(size) or "  -  "

	return string.format("%6s  %s", sstr, tstr)
end
