-- Replace docx tag with string value
-- Author: Jeffry L <paragasu@gmail.com>

local zip = require 'brimworks.zip'
local u = require 'util'
local i = require 'inspect'

local m = {}
m.__index = m

-- @param string filepath full filename path to the docx template
-- @param string tmp directory to process the file
--        using /tmp end up with Renaming temporary file failed: Operation not permitted
--        error. But using other directory is fine.
function m.new(tmp_dir)
  local self = setmetatable({}, m)
  if not tmp_dir then error("Writable temporary directory not provided") end
  self.tmp_dir = tmp_dir
  ngx.log(ngx.NOTICE, "tmp_dir: " .. self.tmp_dir)

  return self
end

function m.replace_tags(self, filepath, tags)
  m.validate_file(filepath)
  self.docx = filepath;
  self.ar = assert(zip.open(self.docx)) 
  self.escaped_tags = m.escape_xml_chars(tags)

  ngx.log(ngx.NOTICE, "open zip " .. self.docx)
  -- file must be writeable
  if not u.file_exists(self.docx) then error(self.docx .. "not exists") end 
  if not u.file_writeable(self.docx) then u.file_set_writeable(self.docx) end

  m.replace_docx_document(self)
  m.replace_docx_header(self)
  m.replace_docx_footer(self)

  self.ar:close()
end

function m.replace_docx_document(self)
  local docume_idx = self.ar:name_locate('word/document.xml')
  m.replace_docx_xml_content(self, docume_idx)
end

function m.replace_docx_header(self)
  local header_idx = self.ar:name_locate('word/header1.xml')
  if header_idx then m.replace_docx_xml_content(self, header_idx) end
end

function m.replace_docx_footer(self)
  local footer_idx = self.ar:name_locate('word/footer1.xml')
  if footer_idx then m.replace_docx_xml_content(self, footer_idx) end
end

-- get the content of xml file inside the zip
function m.replace_docx_xml_content(self, idx)
  local file = assert(self.ar:open(idx))
  local stat = self.ar:stat(idx) 
  local tpl  = file:read(stat.size) 
  self.ar:replace(idx, 'string', m.replace_xml_tags(self, tpl))
  file:close()
end

function m.replace_xml_tags(self, tpl)
  return string.gsub(tpl, '#%a+%.[%a%s%d]+#', self.escaped_tags) or ''
end

function m.validate_file(filepath)
  if type(filepath) ~= 'string' then error('Invalid docx file') end
  if not string.match(filepath, '%.docx') then error('Only docx file supported ' .. filepath) end
  if string.find(filepath, '%.%/') then error('Relative path using ./ not supported ' .. filepath) end
  if string.find(filepath, '%~%/') then error('Relative path using ~/ not supported ' .. filepath) end
  if not u.file_exists(filepath) then error('File '.. filepath .. ' not exists') end
end

function m.escape_xml_chars(tags)
  local data = {}
  for tag, value in pairs(tags) do
    data[tag] = u.xml_escape_chars(value)
  end
  return data or ''
end

return m
