-- Author: Jeffry L <paragasu@gmail.com>

local zip = require 'brimworks.zip'
local xml = require 'xml'
local lfs = require 'lfs'
local exec = require 'resty.exec'
local i = require 'inspect'
local m = {}

function m:new(filepath)
  if type(filepath) ~= 'string' then error('Invalid docx file') end
  if not string.match(filepath, '%.docx') then error('Only docx file supported') end
  if string.find(filepath, '%.%/') then error('Relative path using ./ not supported ' .. filepath) end
  if string.find(filepath, '%~%/') then error('Relative path using ~/ not supported ' .. filepath) end
  if not m.file_exists(filepath) then error('File '.. filepath .. ' not exists') end
  self.docx = m.get_cleaned_docx_file(filepath)
  self.tag_pattern = '#%a+%.%a+%s?%a+#'
  return setmetatable(m, self)
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

-- check if directory writeable
function m.dir_writeable(dirname)
  local stat = lfs.attributes(dirname)
  if not stat then error("Directory do not exists") end
  local perm = string.sub(stat.permissions, 8, 8)
  return perm == 'w'
end

function m:replace(tags)
  local ar = assert(zip.open(self.docx)) 
  local header_idx = ar:name_locate('word/header1.xml')
  local footer_idx = ar:name_locate('word/footer1.xml')
  local docume_idx = ar:name_locate('word/document.xml')
  local header_src = m:get_docx_xml_content(header_idx, tags)
  local footer_src = m:get_docx_xml_content(footer_idx, tags)
  local docume_src = m:get_docx_xml_content(docume_idx, tags)
  ar:replace(header_idx, 'string', header_src) 
  ar:replace(footer_idx, 'string', footer_src) 
  ar:replace(docume_idx, 'string', docume_src) 
  ar:close()
end

-- get the content of xml file inside the zip
-- @param string word/document.xml, word/footer1.xml or word/header1.xml
function m:get_docx_xml_content(idx, tags)
  local ar = assert(zip.open(self.docx)) 
  local file = assert(ar:open(idx))
  local stat = ar:stat(idx) 
  local tpl  = file:read(stat.size) 
  ar:close()
  return string.gsub(tpl, self.tag_pattern, tags)
end

-- get full filename of the cleaned docx file 
-- @param string original docx template file
-- @return string cleaned xml filename
function m.get_cleaned_docx_file(docx_file)
  local doc = m.get_filename(docx_file)
  local tmp_doc = '/tmp/'.. doc
  if not m.file_exists(tmp_doc) then m.clean_docx_xml(docx_file) end
  if not m.file_exists(tmp_doc) then
    return error('Fail to generate cleaned docx with libreoffice ' .. tmp_doc) 
  end
  return tmp_doc
end

-- clean docx xml using libreoffice
-- /usr/bin/libreoffice --headless --convert-to docx --outdir ~/tmp docx_file
function m.clean_docx_xml(docx_file)
  local exec = require 'resty.exec'
  local prog = exec.new('/tmp/exec.sock')
  local cmd  = 'libreoffice --headless --convert-to docx --outdir /tmp "' .. docx_file .. '"'
  local res, err = prog('bash', '-c', cmd);
  if string.find(res.stdout, "using filter") then return true end
  return false
end

-- copy file to public directory
-- @param string full filename for the new file
function m:move(out_filename)
  local dirname = m.get_dirname(out_filename)
  if m.dir_writeable(dirname) then 
    return os.execute('mv "' .. self.docx .. '" "' .. out_filename .. '"') 
  end
end

return m
