{
  This software is provided 'as-is', without any expressed or implied warranty.
  In no event will the author(s) be held liable for any damages arising from
  the use of this software. Permission is granted to anyone to use this software
  for any purpose. If you use this software in a product, an acknowledgment
  in the product documentation would be deeply appreciated but is not required.

  In the case of the GOLD Parser Engine source code, permission is granted
  to anyone to alter it and redistribute it freely, subject to the following
  restrictions:

  - The origin of this software must not be misrepresented; you must not claim
    that you wrote the original software.
  - Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.
  - This notice may not be removed or altered from any source distribution

  Copyright © 2015 Theodore Tsirpanis
  Copyright © 2018 Aleg "Kryvich" Azarouski
}
unit Symbol;

interface

uses
  Classes, SysUtils, gold_types, Generics.Collections;

const
  SYMBOL_COMMENT = 'COMMENT';
  SYMBOL_COMMENT_BLOCK = 'COMMENT_BLOCK';
  SYMBOL_COMMENT_LINE = 'COMMENT_LINE';

type
  TGroup = class;

  { TSymbol }

  TSymbol = class
  protected
    FName: string;
    FType: TSymbolType;
    FTableIndex: integer;
    FGroup: TGroup;
  public
    constructor Create; overload;
    constructor Create(n: string; st: TSymbolType; i: integer); overload;
    class function LiteralFormat(const src: string; ForceDelimiter: boolean): string;
    function ToString: string; reintroduce; overload;
    function ToString(const DelimitTerminals: boolean): string; reintroduce; overload;
    property SymbolGroup: TGroup read FGroup write FGroup;
    property Name: string read FName write FName;
    property TableIndex: integer read FTableIndex write FTableIndex;
    property SymbolType: TSymbolType read FType write FType;
  end;

  TSymList = TObjectList<TSymbol>;

  { TSymbolList }

  TSymbolList = class(TSymList)
    function FindByName(const n: string): TSymbol;
    function ToString: string; overload; override;
  end;

  { TGroup }

  TGroup = class
  private
    FName: string;
    FContainer, FStart, FEnd: TSymbol;
    FAdvMode: TAdvanceMode;
    FEndingMode: TEndingMode;
    FIndex: integer;
    FNesting: TIntegerList;
    procedure SetContainer(AValue: TSymbol);
    procedure SetEnd(AValue: TSymbol);
    procedure SetStart(AValue: TSymbol);
  public
    constructor Create;
    destructor Destroy; override;
    property Name: string read FName write FName;
    property Container: TSymbol read FContainer write SetContainer;
    property Start: TSymbol read FStart write SetStart;
    property _End: TSymbol read FEnd write SetEnd;
    property AdvanceMode: TAdvanceMode read FAdvMode write FAdvMode;
    property EndingMode: TEndingMode read FEndingMode write FEndingMode;
    property Index: integer read FIndex write FIndex;
    property Nesting: TIntegerList read FNesting write FNesting;
  end;

  TGroupList = TObjectList<TGroup>;

implementation

uses
  Character;

{ TSymbolList }

function TSymbolList.FindByName(const n: string): TSymbol;
var
  sm: TSymbol;
begin
  Result := nil;
  for sm in self do
    if SameText(sm.Name, n) then
      Exit(sm);
end;

function TSymbolList.ToString: string;
var
  i: TSymbol;
begin
  Result := '';
  for i in Self do
    Result := Result + ' ' + i.ToString;
  Result := Trim(Result);
end;

{ TSymbol }

class function TSymbol.LiteralFormat(const src: string;
  ForceDelimiter: boolean): string;

  function IsLetter(const c: char): boolean;
  begin
    Result := CharInSet(c.ToLower, ['a'..'z']);
  end;

var
  i: integer;
  c: char;
begin
  if src = '''' then
    Result := ''''''
  else
  begin
    if not ForceDelimiter then
    begin
      ForceDelimiter := (Length(src) = 0) or IsLetter(src[1]);
      if not ForceDelimiter then
      begin
        i := 1;
        while (not ForceDelimiter) and (i < Length(src)) do
        begin
          c := src[i];
          ForceDelimiter := not (IsLetter(c) or (CharInSet(c, ['.', '-', '_'])));
          Inc(i);
        end;
      end;
    end;
    if ForceDelimiter then
      Result := '''' + src + ''''
    else
      Result := src;
  end;
end;

constructor TSymbol.Create;
begin
  inherited;
end;

constructor TSymbol.Create(n: string; st: TSymbolType; i: integer);
begin
  inherited Create;
  FName := n;
  FType := st;
  FTableIndex := i;
end;

function TSymbol.ToString: string;
begin
  Result := ToString(False);
end;

function TSymbol.ToString(const DelimitTerminals: boolean): string;
begin
  case SymbolType of
    stNON_TERMINAL: Result := '<' + Name + '>';
    stCONTENT: Result := LiteralFormat(Name, DelimitTerminals);
    else
      Result := '(' + Name + ')';
  end;
end;

{ TGroup }

procedure TGroup.SetStart(AValue: TSymbol);
begin
  FStart := AValue;
  FStart.SymbolGroup := self;
end;

procedure TGroup.SetEnd(AValue: TSymbol);
begin
  FEnd := AValue;
  FEnd.SymbolGroup := self;
end;

procedure TGroup.SetContainer(AValue: TSymbol);
begin
  FContainer := AValue;
  FContainer.SymbolGroup := self;
end;

constructor TGroup.Create;
begin
  FAdvMode := amCharacter;
  FEndingMode := emClosed;
  FNesting := TIntegerList.Create;
end;

destructor TGroup.Destroy;
begin
  FNesting.Free;
  inherited Destroy;
end;

end.
