const parse = require("../imiv-parser").parse;
const fs = require("fs");
const expect = require('chai').expect;
const dir = __dirname + "/testcases/";

describe('imiv-parser', function() {
  describe('basic parser functionality', function() {

    it('ブロックコメントがエラーなく無視されること', function() {
      expect(parse("/* hello */")).deep.equal([]);
    });
    it('行コメントがエラーなく無視されること', function() {
      expect(parse("// hello\n")).deep.equal([]);
    });
    it('文末の改行で終わらない行コメントがエラーなく無視されること', function() {
      expect(parse("// hello")).deep.equal([]);
    });
    it('ブロックコメントと行コメントの混在がエラーなく無視されること', function() {
      expect(parse(" // hello\n /* world */ \n ")).deep.equal([]);
    });

    it('description ディレクティブがエラーなくパースできること', function() {
      expect(parse("#description 'Thing' class owl:Thing ; ")).deep.equal([{
        "type": "class",
        "prefix": "owl",
        "name": "Thing",
        "metadata": [{
          "type": "description",
          "data": "Thing"
        }]
      }]);
    });
    it('ディレクティブ名が省略された場合は description を補完してパースされること', function() {
      expect(parse("#'Thing' class owl:Thing ; ")).deep.equal([{
        "type": "class",
        "prefix": "owl",
        "name": "Thing",
        "metadata": [{
          "type": "description",
          "data": "Thing"
        }]
      }]);
    });
    it('ディレクティブ前後の空白がエラーなく無視されること', function() {
      expect(parse(" # description 'Thing' class owl:Thing ; ")).deep.equal([{
        "type": "class",
        "prefix": "owl",
        "name": "Thing",
        "metadata": [{
          "type": "description",
          "data": "Thing"
        }]
      }]);
    });

    it('基本的なクラス定義文がパースできること', function() {
      expect(parse("class a:Animal;"))
        .deep.equal(parse("classa:Animal;"))
        .deep.equal(parse(" class a:Animal ; "))
        .deep.equal(parse("/*動物*/ class a:Animal ; "))
        .deep.equal(parse("class a:Animal ; //動物"))
        .deep.equal([{
          "type": "class",
          "prefix": "a",
          "name": "Animal"
        }]);
    });
    it('deprecated なクラス定義文がパースできること', function() {
      expect(parse("deprecated class b:Human;"))
        .deep.equal(parse("deprecatedclassb:Human;"))
        .deep.equal(parse(" deprecated class b:Human ; "))
        .deep.equal([{
          "type": "class",
          "prefix": "b",
          "name": "Human",
          "deprecated": true
        }]);
    });

    it('型制約を持つクラス定義文がパースできること', function() {
      expect(parse("class b:Human{@a:Animal};"))
        .deep.equal(parse("classb:Human{@a:Animal};"))
        .deep.equal(parse(" class b:Human { @ a:Animal } ; "))
        .deep.equal([{
          "type": "class",
          "prefix": "b",
          "name": "Human",
          "restriction": [{
            "prefix": "a",
            "name": "Animal",
            "type": "type"
          }]
        }]);
    });

    it('型制約を複数持つクラス定義文は文法エラーとなること', function() {
      expect(() => {
        parse("class b:Human{@a:Animal}{@a:OtherAnimal};")
      }).to.throw();
    });

    it('型制約以外の制約を持つクラス定義文は文法エラーとなること', function() {
      expect(() => {
        parse("class b:Human{='hello'};")
      }).to.throw();
    });

    it('deprecated, 型制約の混在するクラス定義文がパースできること', function() {
      expect(parse("deprecated class b:Human{@a:Animal};"))
        .deep.equal(parse("deprecatedclassb:Human{@a:Animal};"))
        .deep.equal(parse(" deprecated class b:Human { @ a:Animal } ; "))
        .deep.equal([{
          "type": "class",
          "prefix": "b",
          "name": "Human",
          "deprecated": true,
          "restriction": [{
            "prefix": "a",
            "name": "Animal",
            "type": "type"
          }]
        }]);
    });

    it('基本的なプロパティ定義文がパースできること', function() {
      expect(parse("property ex:say;"))
        .deep.equal(parse("propertyex:say;"))
        .deep.equal(parse(" property ex:say ; //空白とコメント"))
        .deep.equal([{
          "type": "property",
          "prefix": "ex",
          "name": "say"
        }]);
    });
    it('deprecated なプロパティ定義文がパースできること', function() {
      expect(parse("deprecated property ex:say;"))
        .deep.equal(parse("deprecatedpropertyex:say;"))
        .deep.equal(parse(" deprecated  property ex:say ; //空白とコメント"))
        .deep.equal([{
          "type": "property",
          "prefix": "ex",
          "name": "say",
          "deprecated": true
        }]);
    });
    it('型制約を持つプロパティ定義文がパースできること', function() {
      expect(parse("property ex:say{@ex:Word};"))
        .deep.equal(parse("propertyex:say{@ex:Word};"))
        .deep.equal(parse(" property ex:say { @ ex:Word } ; //空白とコメント"))
        .deep.equal([{
          "type": "property",
          "prefix": "ex",
          "name": "say",
          "restriction": [{
            "type": "type",
            "prefix": "ex",
            "name": "Word"
          }]
        }]);
    });
    it('基本的な set 文がパースできること', function() {
      expect(parse("set ex:Human>ex:say;"))
        .deep.equal(parse("setex:Human>ex:say;"))
        .deep.equal(parse(" set ex:Human > ex:say; //空白とコメント"))
        .deep.equal([{
          "type": "set",
          "class": {
            "name": "Human",
            "prefix": "ex"
          },
          "property": {
            "name": "say",
            "prefix": "ex"
          }
        }]);
    });
    it('deprecated な set 文がパースできること', function() {
      expect(parse("deprecated set ex:Human>ex:say;"))
        .deep.equal(parse("deprecatedsetex:Human>ex:say;"))
        .deep.equal(parse(" deprecated set ex:Human > ex:say; //空白とコメント"))
        .deep.equal([{
          "type": "set",
          "class": {
            "name": "Human",
            "prefix": "ex"
          },
          "property": {
            "name": "say",
            "prefix": "ex"
          },
          "deprecated": true
        }]);
    });

    it('回数制約{1..1}を持つ set 文がパースできること', function() {
      expect(parse("set ex:Human>ex:say{1..1};"))
        .deep.equal(parse("setex:Human>ex:say{1..1};"))
        .deep.equal(parse(" set ex:Human > ex:say { 1 .. 1 } ; //空白とコメント"))
        .deep.equal([{
          "type": "set",
          "class": {
            "name": "Human",
            "prefix": "ex"
          },
          "property": {
            "name": "say",
            "prefix": "ex"
          },
          "restriction": [{
            "type": "cardinality",
            "min": 1,
            "max": 1
          }]
        }]);
    });

    it('回数制約{0..1}を持つ set 文がパースできること', function() {
      expect(parse("set ex:Human>ex:say{0..1};"))
        .deep.equal(parse("setex:Human>ex:say{0..1};"))
        .deep.equal(parse(" set ex:Human > ex:say { 0 .. 1 } ; //空白とコメント"))
        .deep.equal([{
          "type": "set",
          "class": {
            "name": "Human",
            "prefix": "ex"
          },
          "property": {
            "name": "say",
            "prefix": "ex"
          },
          "restriction": [{
            "type": "cardinality",
            "min": 0,
            "max": 1
          }]
        }]);
    });

    it('回数制約{0..n}を持つ set 文がパースできること', function() {
      expect(parse("set ex:Human>ex:say{0..n};"))
        .deep.equal(parse("setex:Human>ex:say{0..n};"))
        .deep.equal(parse(" set ex:Human > ex:say { 0 .. n } ; //空白とコメント"))
        .deep.equal([{
          "type": "set",
          "class": {
            "name": "Human",
            "prefix": "ex"
          },
          "property": {
            "name": "say",
            "prefix": "ex"
          },
          "restriction": [{
            "type": "cardinality",
            "min": 0
          }]
        }]);
    });

    it('回数制約{1..n}を持つ set 文がパースできること', function() {
      expect(parse("set ex:Human>ex:say{1..n};"))
        .deep.equal(parse("setex:Human>ex:say{1..n};"))
        .deep.equal(parse(" set ex:Human > ex:say { 1 .. n } ; //空白とコメント"))
        .deep.equal([{
          "type": "set",
          "class": {
            "name": "Human",
            "prefix": "ex"
          },
          "property": {
            "name": "say",
            "prefix": "ex"
          },
          "restriction": [{
            "type": "cardinality",
            "min": 1
          }]
        }]);
    });

    it('基本的な use 文がパースできること', function() {
      expect(parse("use ex:Human>ex:say;"))
        .deep.equal(parse("use ex:Human>ex:say;"))
        .deep.equal(parse(" use ex:Human > ex:say ; //空白とコメント"))
        .deep.equal([{
          "type": "use",
          "class": {
            "name": "Human",
            "prefix": "ex",
            "next": {
              "name": "say",
              "prefix": "ex"
            }
          }
        }]);
    });
    it('多階層の use 文がパースできること', function() {
      expect(parse("use ic:事物型>ic:ID>ic:識別値;"))
        .deep.equal([{
          "type": "use",
          "class": {
            "name": "事物型",
            "prefix": "ic",
            "next": {
              "name": "ID",
              "prefix": "ic",
              "next": {
                "name": "識別値",
                "prefix": "ic"
              }
            }
          }
        }]);
    });
    it('回数制約を持つ use 文がパースできること', function() {
      expect(parse("use ex:Human>ex:say{1..1};"))
        .deep.equal(parse("use ex:Human>ex:say{1..1};"))
        .deep.equal(parse(" use ex:Human > ex:say { 1 .. 1 } ; //空白とコメント"))
        .deep.equal([{
          "type": "use",
          "class": {
            "name": "Human",
            "prefix": "ex",
            "next": {
              "name": "say",
              "prefix": "ex",
              "restriction": [{
                "type": "cardinality",
                "min": 1,
                "max": 1
              }]
            }
          }
        }]);
    });
    it('基本的なデータモデル文をパースできること', function() {
      expect(parse("datamodel;"))
        .deep.equal(parse(" datamodel ; "))
        .deep.equal([{
          "type": "datamodel"
        }]);
    });

    it('制約のあるデータモデル文は文法エラーとなること', function() {
      expect(() => parse("datamodel {$'http://example.org/'};")).to.throw();
    });

    it('基本的な語彙定義文をパースできること', function() {
      expect(parse('vocabulary "http://example.org/";'))
        .deep.equal(parse(' vocabulary "http://example.org/"; '))
        .deep.equal([{
          "type": "vocabulary",
          "data": "http://example.org/"
        }]);
    });

  });

  describe('file-based test cases', function() {

    var files = fs.readdirSync(dir);
    files.filter(function(a) {
        return a.endsWith(".json");
      })
      .filter(function(a) {
        return files.indexOf(a.replace(".json", ".txt")) !== -1;
      })
      .forEach(function(a) {
        var json = JSON.parse(fs.readFileSync(dir + a, "UTF-8"));
        var txt = fs.readFileSync(dir + a.replace(".json", ".txt"), "UTF-8");
        it(`入力 ${a.replace(".json",".txt")} と出力 ${a} が一致すること`, function() {
          expect(parse(txt)).deep.equal(json);
        });
      });
    it('コア語彙2.4.0の語彙定義をエラーなくパースできること', function() {
      expect(function() {
        var txt = fs.readFileSync(dir + "core240.imiv.txt", "UTF-8");
        try {
          var a = parse(txt);
          return a;
        } catch (e) {
          console.log(JSON.stringify(e, null, "  "));
          console.log("<" + txt.substr(0, 5) + ">");
          throw e;
        }
      }).not.to.throw();
    });

  });

});
