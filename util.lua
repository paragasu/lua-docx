-- Common utility function
-- Author: Jeffry L <paragasu@gmail.com>

local m = {}
m.__index = m

-- get the filename given full path
-- @param string path
-- @return string filename
function m.get_filename(path)
  if type(path) ~= 'string' then error('Invalid filename') end
  return string.match(path, '[%w%d%s%-%._]+%.docx')
end

-- get directory name
function m.get_dirname(path)
  local filename = m.get_filename(path)
  local start_pos = string.find(path, filename, 1, true) - 2
  local dirname = string.sub(path, 1, start_pos)
  --ngx.log(ngx.ERR, "filename:" .. filename .. " dirname: " .. dirname)
  return dirname
end

-- check if file exists
-- @param string full path to filename
-- @return boolean
function m.file_exists(filename)
  if type(filename)~="string" then return false end
  if not lfs.attributes(filename) then return false end
  return true
end

-- make file writeable
function m.file_set_writeable(file)
  return os.execute('chmod +w "' .. file .. '"')
end

-- check if directory/file writeable
function m.file_is_writeable(file)
  if not m.file_exists(file) then return false end
  local stat = lfs.attributes(file)
  if not stat then error(file .. "do not exists") end
  local perm = string.sub(stat.permissions, 8, 8)
  return perm == 'w'
end

-- escape xml chars
function m.xml_escape_chars(str)
  local xml_chars = {
    ['<'] = "&#60;",
    ['>'] = "&#62;",
    ['&'] = "&#38;",
    ["'"] = "&#39;",  -- single quote
    ['"'] = "&#34;"   -- double quote
  } 
  return string.gsub(str, '[<>&\'"]', xml_chars) 
end

return m
