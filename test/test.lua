local docx = require 'docx'
local doc  = docx:new('./test/test.docx')
--doc:clean_xml()
doc:replace(function(w)
  print(w)
end)

describe('Docx', function()
  it('get_filename', function()
    local name = doc.get_filename('./test/test.docx') 
    assert.are.equal(name, 'test.docx')
  end) 

  it('get_filename', function()
    local name = doc.get_filename('./test/File Cover - Copy.docx') 
    assert.are.equal(name, 'File Cover - Copy.docx')
  end) 

  it('get_filename', function()
    local name = doc.get_filename('./test/20170418 Template fields.docx') 
    assert.are.equal(name, '20170418 Template fields.docx')
  end) 

  it('get_filename', function()
    local name = doc.get_filename('./test/20170418_Template_fields.docx') 
    assert.are.equal(name, '20170418_Template_fields.docx')
  end) 
end)
