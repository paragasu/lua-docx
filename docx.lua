-- Author: Jeffry L <paragasu@gmail.com>

local zip = require 'brimworks.zip'
local xml = require 'xml'
local lfs = require 'lfs'
local exec = require 'resty.exec'
local sock_file = '/tmp/exec.sock' 
local i = require 'inspect'

-- using /tmp end up with Renaming temporary file failed: Operation not permitted
-- error. But using other directory if fine.
local home_dir = os.getenv('HOME') or lfs.currentdir()
local tmp_dir  = home_dir .. '/tmp'
ngx.log(ngx.ERR, "tmp_dir: " .. tmp_dir)
local m = {}
m.__index = m

function m:new(filepath)
  local self = setmetatable({}, m)
  if type(filepath) ~= 'string' then error('Invalid docx file') end
  if not string.match(filepath, '%.docx') then error('Only docx file supported') end
  if string.find(filepath, '%.%/') then error('Relative path using ./ not supported ' .. filepath) end
  if string.find(filepath, '%~%/') then error('Relative path using ~/ not supported ' .. filepath) end
  if not m.file_exists(filepath) then error('File '.. filepath .. ' not exists') end
  self.docx = m.get_cleaned_docx_file(filepath)
  return self
end

-- get the filename given full path
-- @param string path
-- @return string filename
function m.get_filename(path)
  if type(path) ~= 'string' then error('Invalid filename') end
  return string.match(path, '[%w+%s%-_]+%.docx')
end

-- get directory name
function m.get_dirname(path)
  local filename = m.get_filename(path)
  return string.gsub(path, '/'..filename, '')
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
function m.set_file_writeable(file)
  return os.execute('chmod +w ' .. file)
end

-- check if directory/file writeable
function m.is_writeable(file)
  if not m.file_exists(file) then return false end
  local stat = lfs.attributes(file)
  if not stat then error(file .. "do not exists") end
  local perm = string.sub(stat.permissions, 8, 8)
  return perm == 'w'
end

function m:replace(tags)
  ngx.log(ngx.ERR, "open zip " .. self.docx)
  -- file must be writeable
  if not m.is_writeable(self.docx) then
    m.set_file_writeable(self.docx)
  end
  local ar = assert(zip.open(self.docx)) 
  local header_idx = ar:name_locate('word/header1.xml')
  local footer_idx = ar:name_locate('word/footer1.xml')
  local docume_idx = ar:name_locate('word/document.xml')
  local header_src = m:get_docx_xml_content(ar, header_idx, tags)
  local footer_src = m:get_docx_xml_content(ar, footer_idx, tags)
  local docume_src = m:get_docx_xml_content(ar, docume_idx, tags)
  ar:replace(header_idx, 'string', header_src) 
  ar:replace(footer_idx, 'string', footer_src) 
  ar:replace(docume_idx, 'string', docume_src) 
  ar:close()
end

-- get the content of xml file inside the zip
-- @param string word/document.xml, word/footer1.xml or word/header1.xml
function m:get_docx_xml_content(ar, idx, tags)
  local file = assert(ar:open(idx))
  local stat = ar:stat(idx) 
  local tpl  = file:read(stat.size) 
  local tagpattern = '#%a+%.%a+%s?%a+#'
  file:close()
  return string.gsub(tpl, tagpattern, tags) or ''
end

-- get full filename of the cleaned docx file 
-- @param string original docx template file
-- @return string cleaned xml filename
function m.get_cleaned_docx_file(docx_file)
  local doc = m.get_filename(docx_file)
  local tmp_doc = tmp_dir .. '/'.. doc
  if not m.file_exists(tmp_doc) then m.clean_docx_xml(docx_file) end
  return tmp_doc
end

-- clean docx xml using libreoffice
-- /usr/bin/libreoffice --headless --convert-to docx --outdir ~/tmp docx_file
function m.clean_docx_xml(docx_file)
  if not m.is_writeable(sock_file) then
    ngx.log(ngx.ERR, sock_file .. ' is not writeable') 
  end
  local prog = exec.new(sock_file)
  local cmd  = 'libreoffice --headless --convert-to docx --outdir ' .. tmp_dir .. ' "' .. docx_file .. '"'
  local res, err = prog('bash', '-c', cmd);
  if res and string.find(res.stdout, "using filter") then 
    m.set_file_writeable(tmp_dir .. '/' .. m.get_filename(docx_file))
    return true 
  else
    error("Failed to generate a clean docx file: " .. cmd .. i(res))  
  end
end

-- copy file to public directory
-- @param string full filename for the new file
function m:move(out_filename)
  local dirname = m.get_dirname(out_filename)
  if m.is_writeable(dirname) then 
    return os.execute('mv "' .. self.docx .. '" "' .. out_filename .. '"') 
  end
end

return m
