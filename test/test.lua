reggae = require('reggae')
lu = require('luaunit')
JSON = require('JSON')

TestJson = {}

function TestJson:testLeafFoo()
   local foo = reggae.Target('foo.d')
   lu.assertEquals(JSON:decode(foo:to_json()),
                   JSON:decode([[
                     {"type": "fixed",
                      "command": {},
                      "outputs": ["foo.d"],
                      "dependencies": {"type": "fixed", "targets": []},
                      "implicits": {"type": "fixed", "targets": []}}]]))
end

function TestJson:testLeafBar()
   local bar = reggae.Target('bar.d')
   lu.assertEquals(JSON:decode(bar:to_json()),
                   JSON:decode([[
                     {"type": "fixed",
                      "command": {},
                      "outputs": ["bar.d"],
                      "dependencies": {"type": "fixed", "targets": []},
                      "implicits": {"type": "fixed", "targets": []}}]]))
end


function TestJson:testBuild()
   local bld = reggae.Build(reggae.Target('foo',
                                          'dmd -offoo foo.d',
                                          {reggae.Target('foo.d')}))
   lu.assertEquals(JSON:decode(bld:to_json()),
                   JSON:decode([[
[{"type": "fixed",
          "command": {"type": "shell",
                      "cmd": "dmd -offoo foo.d"},
          "outputs": ["foo"],
          "dependencies": {"type": "fixed",
                           "targets":
                           [{"type": "fixed",
                             "command": {},
                           "outputs": ["foo.d"],
                           "dependencies": {
                               "type": "fixed",
                               "targets": []},
                           "implicits": {
                               "type": "fixed",
                               "targets": []}}]},
          "implicits": {"type": "fixed", "targets": []}}]
   ]]))
end

function TestJson:testProjectDirInclude()
   local main_obj = reggae.Target('main.o',
                                  'dmd -I$project/src -c $in -of$out',
                                  reggae.Target('src/main.d'))
   lu.assertEquals(JSON:decode(main_obj:to_json()),
                   JSON:decode([[
         {"type": "fixed",
          "command": {"type": "shell",
                      "cmd": "dmd -I$project/src -c $in -of$out"},
          "outputs": ["main.o"],
          "dependencies": {"type": "fixed",
                           "targets": [
                               {"type": "fixed",
                                "command": {}, "outputs": ["src/main.d"],
                                "dependencies": {
                                    "type": "fixed",
                                    "targets": []},
                                "implicits": {
                                    "type": "fixed",
                                    "targets": []}}]},
          "implicits": {
              "type": "fixed",
              "targets": []}}
   ]]))
end

function TestJson:testLinkFixed()
   local main_obj = reggae.Target('main.o',
                                  'dmd -I$project/src -c $in -of$out',
                                  reggae.Target('src/main.d'))
   local maths_obj = reggae.Target('maths.o',
                                   'dmd -c $in -of$out',
                                   reggae.Target('src/maths.d'))
   local app = reggae.link({exe_name = 'myapp',
                            dependencies = {main_obj, maths_obj},
                            flags = '-L-M'})
   bld = reggae.Build(app)

   assertSameJson(bld:to_json(),
                  [[
        [{"type": "fixed",
          "command": {"type": "link", "flags": "-L-M"},
          "outputs": ["myapp"],
          "dependencies": {
              "type": "fixed",
              "targets":
              [{"type": "fixed",
                "command": {"type": "shell",
                            "cmd": "dmd -I$project/src -c $in -of$out"},
                "outputs": ["main.o"],
                "dependencies": {"type": "fixed",
                                 "targets": [
                                     {"type": "fixed",
                                      "command": {}, "outputs": ["src/main.d"],
                                      "dependencies": {
                                          "type": "fixed",
                                          "targets": []},
                                      "implicits": {
                                          "type": "fixed",
                                          "targets": []}}]},
                "implicits": {
                    "type": "fixed",
                    "targets": []}},
               {"type": "fixed",
                "command": {"type": "shell", "cmd":
                            "dmd -c $in -of$out"},
                "outputs": ["maths.o"],
                "dependencies": {
                    "type": "fixed",
                    "targets": [
                        {"type": "fixed",
                         "command": {}, "outputs": ["src/maths.d"],
                         "dependencies": {
                             "type": "fixed",
                             "targets": []},
                         "implicits": {
                             "type": "fixed",
                             "targets": []}}]},
                "implicits": {
                    "type": "fixed",
                    "targets": []}}]},
          "implicits": {
              "type": "fixed",
              "targets": []}}]
   ]])
end


function TestJson:testLinkDynamic()
   local objs = reggae.object_files({flags = '-I$project/src', src_dirs = {'src'}})
   local app = reggae.link({exe_name = 'myapp', dependencies = objs, flags = '-L-M'})
   local bld = reggae.Build(app)
   assertSameJson(bld:to_json(),
                  [[
        [{"type": "fixed",
          "command": {"type": "link", "flags": "-L-M"},
          "outputs": ["myapp"],
          "dependencies": {
              "type": "dynamic",
              "func": "objectFiles",
              "src_dirs": ["src"],
              "exclude_dirs": [],
              "src_files": [],
              "exclude_files": [],
              "flags": "-I$project/src",
              "includes": [],
              "string_imports": []},
          "implicits": {
              "type": "fixed",
              "targets": []}}]
]])
end


function TestJson:testStaticLib()
   local lib = reggae.static_library('libstuff.a',
                                     {flags = '-I$project/src',
                                      src_dirs = {'src'}})
   local app = reggae.link({exe_name = 'myapp',
                            dependencies = lib,
                            flags = '-L-M'})
   local bld = reggae.Build(app)
   assertSameJson(bld:to_json(),
                  [[
        [{"type": "fixed",
          "command": {"type": "link", "flags": "-L-M"},
          "outputs": ["myapp"],
          "dependencies": {
              "type": "dynamic",
              "func": "staticLibrary",
              "name": "libstuff.a",
              "src_dirs": ["src"],
              "exclude_dirs": [],
              "src_files": [],
              "exclude_files": [],
              "flags": "-I$project/src",
              "includes": [],
              "string_imports": []},
          "implicits": {
              "type": "fixed",
              "targets": []}}]
   ]])
end

function TestJson.testScriptLike()
   local app = reggae.scriptlike({src_name = 'src/main.d',
                                  exe_name = 'leapp',
                                  flags = '-g',
                                  includes = {'src'}})
   local bld = reggae.Build(app)
   assertSameJson(bld:to_json(),
                  [[
        [{"type": "dynamic",
          "func": "scriptlike",
          "src_name": "src/main.d",
          "exe_name": "leapp",
          "link_with": {"type": "fixed", "targets": []},
          "flags": "-g",
          "includes": ["src"],
          "string_imports": []}]
   ]])
end

function assertSameJson(json1, json2)
   lu.assertEquals(JSON:decode(json1), JSON:decode(json2))
end

lu.LuaUnit.verbosity = 2
os.exit(lu.LuaUnit.run())
