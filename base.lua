#!/usr/bin/env lua
-- VLE - Visual Lua Editor.  Not to be confused with VLED. --

local vt = require("term/iface")
local kbd = require("term/kbd")

local args = {...}

local buffers = {}
local current = 1

local function mkbuffer(file)
  local n = buffers[#buffers + 1]
  buffers[n] = {lines = {""}, unsaved = false, cached = {}, scroll = 0, line = 1, cursor = 0}
  local handle = io.open(file, "r")
  if not handle then
    return
  end
end
