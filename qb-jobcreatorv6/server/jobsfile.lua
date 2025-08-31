JobsFile = JobsFile or {}
local JobsFile = JobsFile

local RESOURCE = 'qb-core'
local FILE = 'shared/jobs.lua'

function JobsFile.Load()
  local content = LoadResourceFile(RESOURCE, FILE)
  if not content then return {}, true end
  local env = { QBShared = {} }
  local fn, err = load(content, '@'..FILE, 't', env)
  if not fn then print('JobsFile.Load error:', err) return {}, true end
  local ok, execErr = pcall(fn)
  if not ok then print('JobsFile.Load exec error:', execErr) return {}, true end
  return env.QBShared.Jobs or {}, env.QBShared.ForceJobDefaultDutyAtLogin
end

local function serialize(val, indent)
  indent = indent or 0
  local t = type(val)
  if t == 'table' then
    local lines = {'{\n'}
    local keys = {}
    for k in pairs(val) do keys[#keys+1] = k end
    table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
      local key
      if type(k) == 'string' and k:match('^%a[%w_]*$') then
        key = k .. ' = '
      else
        key = '[' .. string.format('%q', k) .. '] = '
      end
      lines[#lines+1] = string.rep('  ', indent+1) .. key .. serialize(val[k], indent+1) .. ',\n'
    end
    lines[#lines+1] = string.rep('  ', indent) .. '}'
    return table.concat(lines)
  elseif t == 'string' then
    return string.format('%q', val)
  elseif t == 'number' or t == 'boolean' then
    return tostring(val)
  else
    return 'nil'
  end
end

function JobsFile.Save(jobs)
  jobs = jobs or (QBCore and QBCore.Shared and QBCore.Shared.Jobs) or {}
  local force = QBCore and QBCore.Shared and QBCore.Shared.ForceJobDefaultDutyAtLogin
  local lines = {}
  lines[#lines+1] = 'QBShared = QBShared or {}'
  if force ~= nil then
    lines[#lines+1] = 'QBShared.ForceJobDefaultDutyAtLogin = ' .. tostring(force)
  end
  lines[#lines+1] = 'QBShared.Jobs = ' .. serialize(jobs, 0)
  SaveResourceFile(RESOURCE, FILE, table.concat(lines, '\n') .. '\n', -1)
end

return JobsFile
