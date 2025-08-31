DB = DB or {}
local DB = DB

local function exec(q, p) p = p or {}; return MySQL.query.await(q, p) end
local function scalar(q, p) p = p or {}; return MySQL.scalar.await(q, p) end

function DB.EnsureSchema()
  exec([[CREATE TABLE IF NOT EXISTS jobcreator_jobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) UNIQUE,
    label VARCHAR(64),
    type VARCHAR(64) DEFAULT 'generic',
    whitelisted TINYINT(1) DEFAULT 0,
    grades LONGTEXT,
    actions LONGTEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )]])

  exec([[CREATE TABLE IF NOT EXISTS jobcreator_zones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job VARCHAR(64),
    ztype VARCHAR(32),
    label VARCHAR(64),
    coords LONGTEXT,
    radius FLOAT DEFAULT 2.0,
    data LONGTEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )]])

  exec([[CREATE TABLE IF NOT EXISTS jobcreator_accounts (
    job VARCHAR(64) PRIMARY KEY,
    balance INT DEFAULT 0
  )]])
end

function DB.SaveJob(job)
  exec([[INSERT INTO jobcreator_jobs (name,label,type,whitelisted,grades,actions)
    VALUES (?,?,?,?,?,?)
    ON DUPLICATE KEY UPDATE label=VALUES(label), type=VALUES(type), whitelisted=VALUES(whitelisted), grades=VALUES(grades), actions=VALUES(actions)]],
    { job.name, job.label, job.type or 'generic', job.whitelisted and 1 or 0, json.encode(job.grades), json.encode(job.actions) })
end

function DB.GetJobs()
  return exec('SELECT * FROM jobcreator_jobs') or {}
end

function DB.DeleteJob(name)
  exec('DELETE FROM jobcreator_jobs WHERE name=?', { name })
  exec('DELETE FROM jobcreator_zones WHERE job=?', { name })
  exec('DELETE FROM jobcreator_accounts WHERE job=?', { name })
end

function DB.SaveZone(zone)
  exec([[INSERT INTO jobcreator_zones (job,ztype,label,coords,radius,data) VALUES (?,?,?,?,?,?)]],
    { zone.job, zone.ztype, zone.label or zone.ztype, json.encode(zone.coords), zone.radius or 2.0, json.encode(zone.data or {}) })
end

function DB.GetZones() return exec('SELECT * FROM jobcreator_zones') or {} end
function DB.DeleteZone(id) exec('DELETE FROM jobcreator_zones WHERE id=?', { id }) end

-- ====== Cuentas ======
function DB.GetAccount(job)
  local bal = scalar('SELECT balance FROM jobcreator_accounts WHERE job=?', { job })
  if not bal then exec('INSERT INTO jobcreator_accounts (job,balance) VALUES (?,0)', { job }); bal = 0 end
  return bal
end
function DB.AddAccount(job, amount) exec('INSERT INTO jobcreator_accounts (job,balance) VALUES (?,?) ON DUPLICATE KEY UPDATE balance=balance+VALUES(balance)', { job, amount }) end
function DB.RemoveAccount(job, amount) exec('UPDATE jobcreator_accounts SET balance = GREATEST(balance-?,0) WHERE job=?', { amount, job }) end

-- ====== Empleados OFFLINE (tabla base de QBCore)
function DB.GetOfflineEmployees(job)
  return exec('SELECT citizenid,charinfo,job FROM players WHERE JSON_EXTRACT(job, "$..name") = ?', { job }) or {}
end
function DB.UpdateOfflineJob(citizenid, jobName, grade, firedJob)
  if Config.MultiJob and Config.MultiJob.Enabled and Config.MultiJob.OfflineTable then
    local t = Config.MultiJob.OfflineTable
    local q = ([[SELECT %s FROM %s WHERE %s=? AND %s<>?]]):format(t.columns.job, t.name, t.columns.citizen, t.columns.job)
    local others = exec(q, { citizenid, firedJob }) or {}
    if #others == 0 then
      local jobJson = json.encode({ name = jobName, label = jobName, grade = { name = tostring(grade), level = tonumber(grade) } })
      exec('UPDATE players SET job=? WHERE citizenid=?', { jobJson, citizenid })
    end
    return
  end
  local jobJson = json.encode({ name = jobName, label = jobName, grade = { name = tostring(grade), level = tonumber(grade) } })
  exec('UPDATE players SET job=? WHERE citizenid=?', { jobJson, citizenid })
end

-- ====== Empleados OFFLINE (tabla multitrabajo, opcional)
function DB.GetOfflineEmployees_Multi(job)
  if not Config.MultiJob or not Config.MultiJob.Enabled or not Config.MultiJob.OfflineTable then return {} end
  local t = Config.MultiJob.OfflineTable
  local q = ([[SELECT p.citizenid,p.charinfo,j.%s AS grade FROM %s j JOIN players p ON p.citizenid = j.%s WHERE j.%s = ?]]):format(t.columns.grade, t.name, t.columns.citizen, t.columns.job)
  return exec(q, { job }) or {}
end
function DB.UpsertMultiJob(citizenid, job, grade)
  if not Config.MultiJob or not Config.MultiJob.Enabled or not Config.MultiJob.OfflineTable then return end
  local t = Config.MultiJob.OfflineTable
  local q = ([[INSERT INTO %s (%s,%s,%s) VALUES (?,?,?) ON DUPLICATE KEY UPDATE %s = VALUES(%s)]]):format(t.name, t.columns.citizen, t.columns.job, t.columns.grade, t.columns.grade, t.columns.grade)
  exec(q, { citizenid, job, grade })
end
function DB.DeleteMultiJob(citizenid, job)
  if not Config.MultiJob or not Config.MultiJob.Enabled or not Config.MultiJob.OfflineTable then return end
  local t = Config.MultiJob.OfflineTable
  local q = ([[DELETE FROM %s WHERE %s=? AND %s=?]]):format(t.name, t.columns.citizen, t.columns.job)
  exec(q, { citizenid, job })
end
function DB.UpdateMultiJobGrade(citizenid, job, grade)
  if not Config.MultiJob or not Config.MultiJob.Enabled or not Config.MultiJob.OfflineTable then return end
  local t = Config.MultiJob.OfflineTable
  local q = ([[UPDATE %s SET %s=? WHERE %s=? AND %s=?]]):format(t.name, t.columns.grade, t.columns.citizen, t.columns.job)
  exec(q, { grade, citizenid, job })
end

function DB.GetActivityCounts()
  local day = scalar('SELECT COUNT(*) FROM players WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 1 DAY)')
  local week = scalar('SELECT COUNT(*) FROM players WHERE last_updated >= DATE_SUB(NOW(), INTERVAL 7 DAY)')
  return { day = day or 0, week = week or 0 }
end

function DB.UpdateZone(id, fields)
  local sets, params = {}, {}
  if fields.label   ~= nil then sets[#sets+1] = 'label=?';   params[#params+1] = fields.label end
  if fields.radius  ~= nil then sets[#sets+1] = 'radius=?';  params[#params+1] = fields.radius end
  if fields.coords  ~= nil then sets[#sets+1] = 'coords=?';  params[#params+1] = json.encode(fields.coords) end
  if fields.data    ~= nil then sets[#sets+1] = 'data=?';    params[#params+1] = json.encode(fields.data) end
  if #sets == 0 then return end
  params[#params+1] = id
  MySQL.query.await(('UPDATE jobcreator_zones SET %s WHERE id=?'):format(table.concat(sets, ',')), params)
end