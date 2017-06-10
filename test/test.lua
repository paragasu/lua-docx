local docx = require 'docx'
local lfs  = require 'lfs'
local doc  = docx:new('/home/rogon/lua-docx/test/test.docx')

require 'busted.runner'()

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

  it('get_dirname', function()
    local name = doc.get_dirname('./test/20170418_Template_fields.docx') 
    assert.are.equal(name, './test')
  end) 

  it('file_exists', function()
    local file = doc.file_exists('/tmp/no-exists')
    assert.are.equal(file, false)
  end)

  it('file_exists', function()
    local file = doc.file_exists(nil)
    assert.are.equal(file, false)
  end)

  it('file_exists', function()
    local file = doc.file_exists(lfs.currentdir() .. '/test/test.docx')
    assert.are.equal(file, true)
  end)

  it('./test is public writeable', function()
    local dir = doc.dir_writeable(lfs.currentdir() .. '/test')
    assert.are.equal(dir, true)
  end)

  it('Output docx using libreoffice', function()
    doc.clean_docx_xml(lfs.currentdir() .. '/test/test.docx') 
  end) 

  it('Replace tags', function()
    local tags = { test = "hello" }
    doc:replace(tags)
  end) 
end)
