-- TESTS/usrcmds_help_spec.lua -- every flag and positional argument of `:ColorMyAscii` has a line in
-- lib.nvim's option float.
--
-- The text comes from the `desc` / `enum_desc` of each ArgSpec in color_my_ascii.bindings.usrcmds
-- (`toggle [scope]`, `schemes switch <name>`) and color_my_ascii.debug.commands (`inspect char`,
-- `inspect group`, `inspect highlight`; they exist only while `debug_enabled` is on, so it is on
-- here). An argument without a text shows up as a bare row in the cheatsheet, so this fails until
-- it is described.

return function(H)
  local eq, ok = H.eq, H.ok

  local okc, composer = pcall(require, 'lib.nvim.bindings.usercmd.composer')
  ok(okc, 'the composer loads')

  -- A lib.nvim older than `help.undocumented` cannot answer the question; that is a missing
  -- feature of the dependency, not a defect of this plugin.
  if type(composer.help.undocumented) ~= 'function' then
    return
  end

  require('color_my_ascii.config').setup({ debug_enabled = true })
  require('color_my_ascii.bindings.usrcmds').enable()
  local handle = composer.registry().ColorMyAscii
  ok(handle ~= nil, ':ColorMyAscii is registered through the composer')

  local missing = {}
  for _, m in ipairs(composer.help.undocumented('ColorMyAscii', { args = true })) do
    missing[#missing + 1] = ('%s %s %s'):format(m.kind, m.route, m.name)
  end
  eq(#missing, 0, ':ColorMyAscii entries without a help text: ' .. table.concat(missing, ', '))

  -- The texts follow the house style: one line, no trailing period, at most 80 characters; an
  -- `enum_desc` key is a value the argument really offers.
  local texts, malformed, stray, args = 0, {}, {}, 0
  for _, route in ipairs(handle:spec().routes) do
    for _, arg in ipairs(route.args or {}) do
      args = args + 1
      local offered = {}
      for _, value in ipairs(arg.enum or arg.values or {}) do
        offered[value] = true
      end
      local all = { arg.desc }
      for value, text in pairs(arg.enum_desc or {}) do
        all[#all + 1] = text
        if not offered[value] then
          stray[#stray + 1] = arg.name .. '=' .. value
        end
      end
      for _, text in ipairs(all) do
        texts = texts + 1
        if text:find('\n', 1, true) or text:sub(-1) == '.' or #text > 80 then
          malformed[#malformed + 1] = text
        end
      end
    end
  end
  ok(args >= 5, 'the five arguments (toggle, schemes switch, three inspect routes) were walked')
  ok(texts >= 7, 'their texts were found')
  eq(#malformed, 0, 'malformed texts: ' .. table.concat(malformed, ' | '))
  eq(#stray, 0, 'enum_desc keys that are no value: ' .. table.concat(stray, ', '))
end
