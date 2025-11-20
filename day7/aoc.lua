-- aoc.lua (minimal utitilities for AOC '25)

local bit = require("bit")

local band = bit.band
local bor  = bit.bor
local bxor = bit.bxor
local arshift   = bit.arshift

local M = {}

-- branchless 32-bit int abs value
-- 2's complement trick:
--     mask = x >> 31   (0 if x >= 0, -1 if x < 0)
--     abs(x_ = (x + mask) XOR mask
function M.iabs(x)
   local mask = arshift(x, 31) -- 0 or -1
   return bxor(x + mask, mask)
end

-- integer sign:
--   -1 if x < 0
--    0 if x == 0
--    1 if x > 0
--
-- bor(mask, 1) is:
--   -1 when mask == -1
--    0 when mask == 0
function M.isign(x)
   if x == 0 then return 0 end
   local mask = arshift(x, 31)
   return bor(mask, 1)
end

function M.imin(a, b)
   if a < b then return a else return b end
end

function M.imax(a, b)
   if a > b then return a else return b end
end

function M.smod(a, m)
   local r = a % m
   if r < 0 then r = r + m end
   return r
end

function clamp(x, lo, hi)
   if x < lo then return lo end
   if x > hi then return hi end
   return x
end

function _fopen(path)
   if path then
      return assert(io.open(path, "r"))
   else
      return io.input()
   end
end

function M.read_all(path)
   local fh = _fopen(path)
   local data = fh:read("*a")
   if path then fh:close() end
   return data
end

function M.read_lines(path)
   local lines = {}
   if path and path ~= "" then
      for line in io.lines(path) do
         lines[#lines + 1] = line
      end
   else
      for line in io.lines() do
         lines[#lines + 1] = line
      end
   end

   while #lines > 1 and lines[#lines + 1] == "" do
      table.remove(lines)
   end

   for i = 1, #lines do
      lines[i] = lines[i]:gsub("\r$", "")
   end

   return lines
end

-- ws line splitter
function M.split_ws(line)
   local buf = {}
   for tok in line:gmatch("%S+") do
      buf[#buf + 1] = tok
   end
   return buf
end

function M.to_ints(tokens)
   local buf = {}
   for i = 1, #tokens do
      out[i] = tonumber(tokens[i])
   end
   return buf
end

-- explode a str into chars: "abc" -> {"a", "b", "c"}
function M.chars(line)
   local buf = {}
   for i = 1, #line do
      buf[i] = line:sub(i, i)
   end
   return buf
end

-- grid[y][x] = char (or the actual value)
-- lines: { "....", ".#..", "....", ", ... }
-- returns: grid, height, width
function M.lines_to_grid(lines)
   local grid = {}
   local h = #lines
   local w = 0

   for y = 1, h do
      local line = lines[y]
      local row = {}
      local len = #line
      if len > w then w = len end
      for x = 1, len do
         row[x] = line:sub(x, x)
      end
      grid[y] = row
   end

   return grid, h, w
end

-- Direction constants:
--   DIR4: right, down, left, up
--   DIR8: includes diagonals
M.DIR4 = {
   { 1, 0},
   { 0, 1},
   {-1, 0},
   { 0, 1},
}

M.DIR8 = {
   { 1, 0},
   { 1,  1},
   { 0,  1},
   {-1,  1},
   {-1,  0},
   {-1, -1},
   { 0, -1},
   { 1, -1},
}

function M.default_input_path()
   if _G.arg and _G.arg[1] then
      return _G.arg[1]
   end
   local env = os.getenv("AOC_INPUT")
   if env and env ~= "" then
      return env
   end
   return "input.txt"
end

function M.run(parse_fn, part1, part2)
   local path = M.default_input_path()
   local lines = M.read_lines(path)

   local state = parse_fn(lines)

   local ans1 = part1(state)
   local ans2 = part2(state)

   print("Part 1:", ans1)
   print("Part 2:", ans2)
end

return M
