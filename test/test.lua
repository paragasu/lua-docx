-- Unit test
-- Author: Jeffry L <paragasu@gmail.com>

local docx = require 'docx'
local util = require 'util'
local lfs  = require 'lfs'
local doc  = docx.new('/home/rogon/lua-docx/tmp')

require 'busted.runner'()

describe('Docx', function()
  it('get_filename', function()
    local name = util.get_filename('./test/doc test.docx') 
    assert.are.equal(name, 'doc test.docx')
  end) 

  it('get_filename', function()
    local name = util.get_filename('./test/File Cover - Copy.docx') 
    assert.are.equal(name, 'File Cover - Copy.docx')
  end) 

  it('get_filename', function()
    local name = util.get_filename('./test/20170418 Template fields.docx') 
    assert.are.equal(name, '20170418 Template fields.docx')
  end) 

  it('get_filename', function()
    local name = util.get_filename('./test/20170418_Template_fields.docx') 
    assert.are.equal(name, '20170418_Template_fields.docx')
  end) 

  it('get_dirname', function()
    local name = util.get_dirname('./test/20170418_Template_fields.docx') 
    assert.are.equal(name, './test')
  end) 

  it('get_dirname', function()
    local name = util.get_dirname('./test/doc test - 01827383.docx') 
    assert.are.equal(name, './test')
  end) 

  it('file_exists', function()
    local file = util.file_exists('/tmp/no-exists')
    assert.are.equal(file, false)
  end)

  it('file_exists', function()
    local file = util.file_exists(nil)
    assert.are.equal(file, false)
  end)

  it('file_exists', function()
    local file = util.file_exists(lfs.currentdir() .. '/test/doc test.docx')
    assert.are.equal(file, true)
  end)

  it('./test is public writeable', function()
    local dir = util.file_writeable(lfs.currentdir() .. '/test')
    assert.are.equal(dir, true)
  end)

  it('Output docx using libreoffice', function()
    --doc:clean_docx_xml(lfs.currentdir() .. '/test/doc test.docx') 
  end) 

  it('Replace tags', function()
    local tags = { test = "hello" }
    doc:replace_tags('/home/rogon/lua-docx/test/doc test.docx', tags)
  end) 

  it('Escape special chars: &', function()
    local result = util.xml_escape_chars("hello &")
    assert.are.equal(result, "hello &#38;")
  end) 

  it('Escape special chars: <', function()
    local result = util.xml_escape_chars("hello <")
    assert.are.equal(result, "hello &#60;")
  end) 

  it('Escape special chars: >', function()
    local result = util.xml_escape_chars("hello >")
    assert.are.equal(result, "hello &#62;")
  end) 

  it('Escape special chars: "', function()
    local result = util.xml_escape_chars('hello "')
    assert.are.equal(result, "hello &#34;")
  end) 

  it("Escape special chars: '", function()
    local result = util.xml_escape_chars("hello '")
    assert.are.equal(result, "hello &#39;")
  end) 

  it('Escape special chars: ""', function()
    local result = util.xml_escape_chars("hello <>")
    assert.are.equal(result, 'hello &#60;&#62;')
  end) 
end)
