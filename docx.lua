local zip = require 'zip'
local xml = require 'xml'
local i = require 'inspect'
local m = {}

function m:new(filepath)
  self.doc_file = filepath 
  self.tag_pattern = '#%a+%.%a+%s?%a+#'
  return setmetatable(m, self)
end

function m:get_template_doc()
  local zfile, err = zip.open(self.doc_file)
  if not zfile then return error('Failed to open ' .. self.doc_file .. ' : ' .. err) end
  local file, err  = zfile:open('word/document.xml')
  if not file then return error('Cannot read document file: ' .. err) end
  return file:read('*a') 
end

function m:replace(tags)
  local tpl, err  = m:get_template_doc() 
  return string.gsub(tpl, self.tag_pattern, tags)
end

function m:download()
  -- prompt browser to download file / open with msword
end

local doc = m:new('/home/paragasu/tmp/test.docx')
doc:replace(function(w)
  print(w)
end)
