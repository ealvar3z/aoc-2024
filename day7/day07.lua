#!/usr/bin/env luajit

-- day07.lua - AoC 2024 Day 7: Bridge Repair (Parts 1 & 2)
--
-- Part 1: operators {+, *}
-- Part 2: operators {+, *, ||}, where || is decimal concatenation.
--
-- model each line as:
--   target: integer T
--   nums:   { a1, a2, ..., an }

local aoc = require "aoc"

----------------------------------------------------------------------
-- Parsing
-- Lines look like:
--   190: 10 19
--   3267: 81 40 27
----------------------------------------------------------------------

local function parse(lines)
    local eqs = {}

    for _, line in ipairs(lines) do
        if line ~= "" then
            local target_str, rest = line:match("^(%d+):%s*(.+)$")
            if target_str and rest then
                local target = tonumber(target_str)
                local nums = {}

                for tok in rest:gmatch("%S+") do
                    nums[#nums + 1] = tonumber(tok)
                end

                eqs[#eqs + 1] = {
                    target = target,
                    nums   = nums,
                }
            end
        end
    end

    return { equations = eqs }
end

----------------------------------------------------------------------
-- Helper: DP with only + and *
--
-- current = set of numeric values reachable after consuming up to a_i
-- next    = set after consuming a_{i+1}
--
-- prune any value > target, because + and * on positive integers
-- cannot bring values back down to target once they exceed it.
----------------------------------------------------------------------

local function is_solvable_plus_mul(target, nums)
    local n = #nums
    if n == 0 then
        return false
    end

    -- Level 1: only a1 is reachable
    local current = { [nums[1]] = true }

    if n == 1 then
        return nums[1] == target
    end

    for i = 2, n do
        local a = nums[i]
        local next_set = {}

        for v, _ in pairs(current) do
            -- v + a
            local s = v + a
            if s <= target then
                next_set[s] = true
            end

            -- v * a
            local p = v * a
            if p <= target then
                next_set[p] = true
            end
        end

        current = next_set

        -- If no values are reachable, we can stop
        if next(current) == nil then
            return false
        end
    end

    return current[target] == true
end

----------------------------------------------------------------------
-- Helper: safe concatenation with target-aware pruning
--
-- want concat(v, a) = decimal concatenation of v and a.
-- Example: v=12, a=345 -> "12" .. "345" = "12345".
--
-- We:
--   1) build cat_str = tostring(v) .. tostring(a)
--   2) compare cat_str to target_str as strings, using length then lexic.
--      If cat_str > target_str, it is useless and we discard it.
--   3) only then convert to number with tonumber(cat_str).
--
-- This keeps us from ever *using* huge numeric values beyond target.
----------------------------------------------------------------------

local function safe_concat_as_number(v, a, target, target_str)
    local cat_str = tostring(v) .. tostring(a)

    -- If concatenated string is longer than target string, it is > target.
    if #cat_str > #target_str then
        return nil
    end

    -- If same length, compare lexicographically.
    if #cat_str == #target_str and cat_str > target_str then
        return nil
    end

    -- At this point we know cat <= target in integer sense,
    -- so converting to Lua number is safe (AoC targets fit in 64-bit range).
    local cat_num = tonumber(cat_str)
    if cat_num == nil or cat_num > target then
        return nil
    end

    return cat_num
end

----------------------------------------------------------------------
-- Helper: DP with +, *, and || (concatenation)
--
-- Same state graph as before, but from each value v we consider:
--   v + a
--   v * a
--   concat(v, a)   (via safe_concat_as_number)
----------------------------------------------------------------------

local function is_solvable_with_concat(target, nums)
    local n = #nums
    if n == 0 then
        return false
    end

    local target_str = tostring(target)

    local current = { [nums[1]] = true }

    if n == 1 then
        return nums[1] == target
    end

    for i = 2, n do
        local a = nums[i]
        local next_set = {}

        for v, _ in pairs(current) do
            -- v + a
            local s = v + a
            if s <= target then
                next_set[s] = true
            end

            -- v * a
            local p = v * a
            if p <= target then
                next_set[p] = true
            end

            -- v || a
            local c = safe_concat_as_number(v, a, target, target_str)
            if c and c <= target then
                next_set[c] = true
            end
        end

        current = next_set

        if next(current) == nil then
            return false
        end
    end

    return current[target] == true
end

----------------------------------------------------------------------
-- Part 1:
--   Sum targets of equations solvable with + and * only.
----------------------------------------------------------------------

local function part1(state)
    local eqs = state.equations
    local total = 0

    for i = 1, #eqs do
        local eq = eqs[i]
        if is_solvable_plus_mul(eq.target, eq.nums) then
            total = total + eq.target
        end
    end

    return total
end

----------------------------------------------------------------------
-- Part 2:
--   Sum targets of equations solvable with +, *, or ||.
--   This includes those already solvable in Part 1 plus the new ones
--   that only become solvable when concatenation is allowed.
----------------------------------------------------------------------

local function part2(state)
    local eqs = state.equations
    local total = 0

    for i = 1, #eqs do
        local eq = eqs[i]
        if is_solvable_with_concat(eq.target, eq.nums) then
            total = total + eq.target
        end
    end

    return total
end

aoc.run(parse, part1, part2)
