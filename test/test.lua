local docx = require 'docx'
local lfs  = require 'lfs'
local doc  = docx.new('/home/rogon/lua-docx/test/doc test.docx', '/home/rogon/lua-docx/tmp')

require 'busted.runner'()

describe('Docx', function()
  it('get_filename', function()
    local name = doc.get_filename('./test/doc test.docx') 
    assert.are.equal(name, 'doc test.docx')
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

  it('get_dirname', function()
    local name = doc.get_dirname('./test/doc test - 01827383.docx') 
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
    local file = doc.file_exists(lfs.currentdir() .. '/test/doc test.docx')
    assert.are.equal(file, true)
  end)

  it('./test is public writeable', function()
    local dir = doc.is_writeable(lfs.currentdir() .. '/test')
    assert.are.equal(dir, true)
  end)

  it('Output docx using libreoffice', function()
    doc:clean_docx_xml(lfs.currentdir() .. '/test/doc test.docx') 
  end) 

  it('Replace tags', function()
    local tags = { test = "hello" }
    --doc:replace(tags)
  end) 

  it('Escape special chars: &', function()
    local tags = { test = "hello &" }
    local result = doc:escape_xml_chars(tags)
    assert.are.equal(result.test, "hello &#38;")
  end) 

  it('Escape special chars: <', function()
    local tags = { test = "hello <" }
    local result = doc:escape_xml_chars(tags)
    assert.are.equal(result.test, "hello &#60;")
  end) 

  it('Escape special chars: >', function()
    local tags = { test = "hello >" }
    local result = doc:escape_xml_chars(tags)
    assert.are.equal(result.test, "hello &#62;")
  end) 

  it('Escape special chars: "', function()
    local tags = { test = 'hello "' }
    local result = doc:escape_xml_chars(tags)
    assert.are.equal(result.test, "hello &#34;")
  end) 

  it("Escape special chars: '", function()
    local tags = { test = "hello '" }
    local result = doc:escape_xml_chars(tags)
    assert.are.equal(result.test, "hello &#39;")
  end) 

  it('Escape special chars: ""', function()
    local tags = { test = 'hello <>' }
    local result = doc:escape_xml_chars(tags)
    assert.are.equal(result.test, 'hello &#60;&#62;')
  end) 
end)
