-- Author: Jeffry L <paragasu@gmail.com>

local zip = require 'brimworks.zip'
local xml = require 'xml'
local lfs = require 'lfs'
local exec = require 'resty.exec'
local sock_file = '/home/rogon/tmp/exec.sock' 
local i = require 'inspect'

local m = {}
m.__index = m

-- @param string filepath full filename path to the docx template
-- @param string tmp directory to process the file
--        using /tmp end up with Renaming temporary file failed: Operation not permitted
--        error. But using other directory is fine.
function m.new(filepath, tmp_dir)
  local self = setmetatable({}, m)
  if type(filepath) ~= 'string' then error('Invalid docx file') end
  if not string.match(filepath, '%.docx') then error('Only docx file supported ' .. filepath) end
  if string.find(filepath, '%.%/') then error('Relative path using ./ not supported ' .. filepath) end
  if string.find(filepath, '%~%/') then error('Relative path using ~/ not supported ' .. filepath) end
  if not m.file_exists(filepath) then error('File '.. filepath .. ' not exists') end
  if not tmp_dir then error("Writable temporary directory not provided") end
  self.tmp_dir = tmp_dir
  self.docx = m.get_cleaned_docx_file(self, filepath)
  ngx.log(ngx.NOTICE, "tmp_dir: " .. self.tmp_dir)
  return self
end

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
function m.set_file_writeable(file)
  return os.execute('chmod +w "' .. file .. '"')
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
  ngx.log(ngx.NOTICE, "open zip " .. self.docx)
  -- file must be writeable
  if not m.file_exists(self.docx) then error(self.docx .. "not exists") end 
  if not m.is_writeable(self.docx) then m.set_file_writeable(self.docx) end
  -- escape xml tags
  local escaped_tags = m:escape_xml_chars(tags)

  local ar = assert(zip.open(self.docx)) 
  local docume_idx = ar:name_locate('word/document.xml')
  local docume_src = m:get_docx_xml_content(ar, docume_idx, escaped_tags)
  ar:replace(docume_idx, 'string', docume_src) 

  -- libreoffice do not generate header1.xml & footer1.xml by default
  local header_idx = ar:name_locate('word/header1.xml')
  if header_idx then
    local header_src = m:get_docx_xml_content(ar, header_idx, escaped_tag)
    ar:replace(header_idx, 'string', header_src) 
  end

  local footer_idx = ar:name_locate('word/footer1.xml')
  if footer_idx then
    local footer_src = m:get_docx_xml_content(ar, footer_idx, escaped_tags)
    ar:replace(footer_idx, 'string', footer_src) 
  end

  ar:close()
end


function m:escape_xml_chars(tags)
  local data = {}
  local xml_chars = {
    ['<'] = "&#60;",
    ['>'] = "&#62;",
    ['&'] = "&#38;",
    ["'"] = "&#39;",  -- single quote
    ['"'] = "&#34;"   -- double quote
  } 
  for tag, value in pairs(tags) do
    data[tag] = string.gsub(value, '[%<%>%&\'%"]', xml_chars) 
  end
  return data
end

-- get the content of xml file inside the zip
-- @param string word/document.xml, word/footer1.xml or word/header1.xml
function m:get_docx_xml_content(ar, idx, tags)
  local file = assert(ar:open(idx))
  local stat = ar:stat(idx) 
  local tpl  = file:read(stat.size) 
  file:close()
  return string.gsub(tpl, '#%a+%.[%a%s%d]+#', tags) or ''
end

-- get full filename of the cleaned docx file 
-- @param string original docx template file
-- @return string cleaned xml filename
function m:get_cleaned_docx_file(docx_file)
  local tmp_doc = self.tmp_dir .. '/'.. m.get_filename(docx_file)
  if m.file_exists(docx_file) and not m.file_exists(tmp_doc) then 
    ngx.log(ngx.ERR, "Generate a clean docx template" .. docx_file)
    m.clean_docx_xml(self, docx_file) 
  end
  return tmp_doc
end

-- clean docx xml using libreoffice
-- /usr/bin/libreoffice --headless --convert-to docx --outdir ~/tmp docx_file
function m:clean_docx_xml(input_docx)
  if not self.tmp_dir then error("tmp_dir is missing " .. i(self.tmp_dir)) end
  if not input_docx then error("Missing input file " .. i(input_docx)) end
  local prog = exec.new(sock_file)
  local cmd  = string.format('/usr/bin/libreoffice --headless --convert-to docx:"MS Word 2007 XML" --outdir %s %q', self.tmp_dir, input_docx)
  --prog.stdin = string.format('--headless --convert-to docx:"MS Word 2007 XML" --outdir %s %q', self.tmp_dir, input_docx)
  local res, err = prog('/bin/bash', '-c', cmd);
  --ngx.log(ngx.ERR, "cmd result", cmd, i(res), i(err)) 
  if res and string.find(res.stdout, "using filter") then 
    --m.set_file_writeable(self.tmp_dir .. '/' .. m.get_filename(docx_file))
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
  else
    error(dirname .. " is not writeable")
  end
end

return m
