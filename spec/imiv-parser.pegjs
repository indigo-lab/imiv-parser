// [2017-10-16] 仕様としての修正点は報告した。現仕様に準拠したもっとも寛容なパーサを実装する方針。
// [2017-10-16] deprecatedclassic:時間型 のような空白のない宣言文は、許容する。（将来の仕様で修正される可能性はある）

// 空白、コメントはパース結果に残さず、無視する
// 任意空白の入る箇所にはコメントが入るものとしている

// 【IMI 定義文書】
// 文と文末の間につくコメント・空白を許容する
// 文頭の Byte order mark は無視する
start = "\uFEFF"? a:statement* IGNORE {return a;}

// 【文】
statement = (vocabularyStatement/datamodelStatement/classStatement/propertyStatement/setStatement/useStatement)

// 【語彙定義文】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
vocabularyStatement = IGNORE a:metadata* IGNORE b:vocabulary IGNORE ";" {
  if(a.length > 0) b.metadata = a;
  return b;
}

// 【語彙定義】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
vocabulary = IGNORE "vocabulary" IGNORE a:quotedLiteral {
  return {
    "type" : "vocabulary",
    "data" : a
  };
}

// 【クラス定義文】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
classStatement = IGNORE a:metadata* IGNORE b:class IGNORE ";" {
  if(a.length > 0) b.metadata = a;
  return b;
}


// 【クラス定義】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
class = IGNORE a:"deprecated"? IGNORE "class" IGNORE b:className IGNORE c:typeRestriction? {
  var obj = b;
  obj.type = "class";
  if(c) obj.restriction = [c];
  if(a) obj.deprecated = true;
  return obj;
}

typeRestriction = IGNORE "{" a:type IGNORE "}" {return a;}

// 【プロパティ定義文】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
propertyStatement = IGNORE a:metadata* IGNORE b:property IGNORE ";" {
  if(a.length > 0) b.metadata = a;
  return b;
}

// 【プロパティ定義】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
property = IGNORE a:"deprecated"? IGNORE "property" IGNORE b:propertyName IGNORE c:restriction* {
  var obj = b;
  obj.type = "property";
  if(c && c.length > 0) obj.restriction = c;
  if(a) obj.deprecated = true;
 return obj;
}

//【プロパティ設定文】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
setStatement = IGNORE a:metadata* IGNORE b:set IGNORE ";" {
  if(a.length > 0) b.metadata = a;
  return b;
}

// 【プロパティ設定】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
set = IGNORE a:"deprecated"? IGNORE "set" IGNORE b:className IGNORE ">" IGNORE c:propertyName IGNORE d:restriction* {
  var obj = {
    type :"set",
    class : b,
    property : c
  };
  if(d.length > 0) obj.restriction = d;
  if(a) obj.deprecated = true;
 return obj;
}

// 【データモデル定義文】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
datamodelStatement = IGNORE a:metadata* IGNORE b:datamodel IGNORE ";" {
  if(a.length > 0) b.metadata = a;
  return b;
}

// 【データモデル定義】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
datamodel = IGNORE "datamodel" {
    var obj = {
      type :"datamodel"
    };
   return obj;
  }

// 【用語使用宣言文】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
useStatement = IGNORE a:metadata* IGNORE b:use IGNORE ";" {
  if(a.length > 0) b.metadata = a;
  return b;
}

// 【用語使用宣言】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
// [2017-10-16] 末尾以外に制約が付与できないのは意図したものであることを確認
use = IGNORE "use" IGNORE a:path IGNORE b:restriction* {
  var obj = {
    type : "use",
    class : a
  };
  if(b.length > 0 ){
    var f = a;
    while(f.next) f = f.next;
    f.restriction = b;
  }
  return obj;
}

// 【メタデータ宣言】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
metadata
  // 一般的なメタデータ
  = IGNORE a:directive IGNORE b:group? IGNORE c:language? IGNORE d:quotedLiteral {
    var obj = {type:a,data:d};
    if(b) obj.group = b;
    if(c) obj.language = c;
    return obj;
  }
  // プレフィックス
  / IGNORE a:directive IGNORE b:group? IGNORE c:language? IGNORE d:prefixStatement {
    var obj = d;
    obj.type = a;
    if(b) obj.group = b;
    if(c) obj.language = c;
    return obj;
  }

// 【名前空間プレフィックス宣言】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
prefixStatement = IGNORE a:namespacePrefix IGNORE b:quotedLiteral {
  a.data = b;
  return a;
}


// 【制約指定】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
restriction = IGNORE "{" a:restrictionMember IGNORE "}" {return a;}

// 【制約】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
restrictionMember = (pattern/cardinality/type/eq/gt/ge/lt/le/charset/order)

// 【パターン制約】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
pattern = IGNORE a:patternLiteral {return {type:"pattern",data:a};}

// 【回数制約】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
cardinality
  = IGNORE min:integer IGNORE ".." IGNORE max:integer {return {type:"cardinality",min:min,max:max};}
  / IGNORE min:integer IGNORE ".." IGNORE "n" {return {type:"cardinality",min:min};}

// 【型制約】
// [2017-10-16] @ と 型名の間は空白を入れてレイアウトすることを意図している
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
type = IGNORE "@" IGNORE a:classObject {a.type = "type"; return a;}

// 【値等価制約】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
eq = IGNORE "=" IGNORE a:(integer / quotedLiteral) {return {type:"eq",data:a};}

// 【値開下限制約】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
gt = IGNORE ">" IGNORE a:integer {return {type:"gt",data:a};}

// 【値下限制約】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
ge = IGNORE ">=" IGNORE a:integer {return {type:"ge",data:a};}

// 【値開上限制約】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
lt = IGNORE "<" IGNORE a:integer {return {type:"lt",data:a};}

// 【値上限制約】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
le = IGNORE "<=" IGNORE a:integer {return {type:"le",data:a};}

// 【使用可能文字制約】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
charset = IGNORE "$" IGNORE a:quotedLiteral {return {type:"charset",data:a};}

// 【プロパティ順序制約】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
order = IGNORE "#" IGNORE a:integer {return {type:"order",data:a};}

// 【厳密構造要素名】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
path = IGNORE a:classObject IGNORE b:propertySequence? IGNORE c:language? {if(b)a.next=b;if(c)a.language=c;return a;}

// 【クラス項目】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
classObject = IGNORE a:className IGNORE b:group? {if(b)a.group = b; return a;}

// 【名前空間プレフィックス指定子】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
// QName の空白は仕様検討課題として報告
namespacePrefix = prefix:identifier IGNORE ":" {return {prefix:prefix};}

// 【クラス用語名】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
className = IGNORE a:namespacePrefix IGNORE b:identifier {a.name = b; return a;}

// 【グループ指定子】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
group = IGNORE a:groupLiteral {return a;}

// 【グループ名リテラル】
// [2017-10-16] これは構文規則由来ではないので、空白許容ルール適用外であることに注意
groupLiteral = "[" a:[^\]]+ "]" {return a.join("");}


// 【プロパティ列】
propertySequence
  = IGNORE ">" IGNORE a:propertyObject IGNORE b:propertySequence? {
    if(b) a.next = b;
    return a;
  }

// 【プロパティ項目】
propertyObject
  = IGNORE a:propertyName IGNORE b:group? {if(b)a.group = b; return a;}

// 【プロパティ用語名】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
propertyName = IGNORE prefix:identifier IGNORE ":" IGNORE name:identifier {return {prefix:prefix,name:name};}

// 【言語指定子】
// 「@に続けてISO 639-1が定める言語コードを指定」＞間の空白は認めない
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
language = IGNORE "@" IGNORE a:languageName {return a;}


// 【ディレクティブ】
// [2017-10-16] 構文規則由来であり、空白許容ルールを導入
// [2017-10-16] identifier が必須ではなく、オプションであることを確認
directive
  = IGNORE "#" IGNORE a:identifier? {return a ? a : "description";}

// 【コメント】
multiLineComment = "/*" a:([^*] / multiLineCommentChar)* "*/" {return a.join("").trim();}
multiLineCommentChar = "*" a:[^/] {return "*" + a;}

// 【行コメント】
// End of file の場合も許容する
singleLineComment = "//" chars:[^\n]* (EOL / EOF) {return chars.join("").trim();}


// 【文字列リテラル】
quotedLiteral = (singleQuotedLiteral / doubleQuotedLiteral)
// 【二重引用符文字列リテラル】
doubleQuotedLiteral = '"' chars:(doubleQuoteEscape / [^"])* '"' {return chars.join("");}
// 【二重引用符エスケープ】
doubleQuoteEscape = '\\"' {return '"';}
// 【引用符文字列リテラル】
singleQuotedLiteral = "'" chars:(singleQuoteEscape / [^'])* "'" {return chars.join("");}
// 【引用符エスケープ】
singleQuoteEscape = "\\'" {return "'";}
// 【整数リテラル】
integer = a:digit+ {return parseInt(a.join(""));}

// 正規表現の中で / が使えない問題、エスケープを用意したほうがよいのでは？
// URL を http:// に限定、とか利用シーンは結構あるので

// 【パターンリテラル】
patternLiteral = "/" chars:(patternEscape / [^/])* "/" {return chars.join("");}
// 【パターンリテラルエスケープ】
patternEscape = '\\/' {return "\/";}

// U+10000-U+EFFFF がエラーになるので除外
// js spec では \u{10000}-\u{effff} とかけば OK だが、PEG が対応していない

// 【識別子】
identifier =
  head:identifierHeadCharacter
  body:identifierBodyCharacter*
  {return head + (body ? body.join("") : "");}

// 【言語名】
languageName = a:languageNameCharacter b:languageNameCharacter {return a + b;}

// 【識別子先頭文字】
identifierHeadCharacter =
  [a-zA-Z_\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]

// 【識別子文字】
identifierBodyCharacter =
  (identifierHeadCharacter / [.\-0-9\u00B7\u0300-\u036f\u203f-\u2040])

// 【数字】
digit = [0-9]

// 【空白文字】
// s = [ \t\r\n\f]+
// w = s?

// 【改行文字】
EOL = "\n"

// 【ファイル終端】
EOF = !.

// 【文字】
char = [\u0009\u000a\u000d\u0020-\ud7ff\ue000-\ufffd]

// 【言語名文字】
languageNameCharacter = [a-zA-Z]

// 【任意空白あるいはコメント】
IGNORE = (multiLineComment / singleLineComment / [ \t\r\n\f])*
