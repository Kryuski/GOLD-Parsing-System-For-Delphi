{
Copyright © 2015 Theodore Tsirpanis
This software is provided 'as-is', without any expressed or implied warranty. In no event will the author(s) be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose. If you use this software in a product, an acknowledgment in the product documentation would be deeply appreciated but is not required.

In the case of the GOLD Parser Engine source code, permission is granted to anyone to alter it and redistribute it freely, subject to the following restrictions:

The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
This notice may not be removed or altered from any source distribution
}
unit Token;

interface

uses
  Classes, SysUtils, Generics.Collections, contnrs, Symbol, gold_types, Production,
  Variable;

type
  TTokenStack = class;
  TReduction = class;

  { TToken }

  TToken = class(TSymbol)
  private
    FState: integer;
    FReduction: TReduction;
    FPosition: TPosition;
    FData: string;
    FText: string;
    FOwnerStack: TTokenStack;
    procedure SetAsSymbol(const s: TSymbol);
    procedure SetOwnerStack(AValue: TTokenStack);
  public
    constructor Create; overload;
    constructor Create(const sym: TSymbol; const dt: TReduction); overload;
    constructor Create(const sym: TSymbol; const dt: TReduction;
      const Pos: TPosition); overload;
    destructor Destroy; override;
    function ToString: string; overload; override;
    procedure AppendData(const s: string);
    property AsSymbol: TSymbol write SetAsSymbol;
    property Data: string read FData write FData;
    property OwnerStack: TTokenStack read FOwnerStack write SetOwnerStack;
    property Position: TPosition read FPosition write FPosition;
    property Reduction: TReduction read FReduction write FReduction;
    property State: integer read FState write FState;
  end;

  TTokList = TList<TToken>;

  { TReduction }

  TReduction = class(TTokList)
  private
    FParent: TProduction;
    FValue: TVariable;
  public
    procedure Execute; virtual;
    property Parent: TProduction read FParent write FParent;
    property Value: TVariable read FValue write FValue;
  end;

  { TTokenStack }

  TTokenStack = class
  private
    FMemberList: TObjectList;
    FOwnedTokens: TObjectList;
    function GetCount: integer;
    function GetItem(Index: integer): TToken;
    procedure FreeOwnedTokens;
  public
    constructor Create(const fobjs: boolean = True);
    destructor Destroy; override;
    procedure Clear;
    procedure Push(TheToken: TToken);
    function Pop: TToken;
    function Top: TToken;
    property Count: integer read GetCount;
    property Items[Index: integer]: TToken read GetItem; default;
    property MemberList: TObjectList read FMemberList;
  end;

function DrawReductionTree(TheReduction: TReduction): string;

implementation

uses
  Types;

procedure PrintParseTree(Text: string; Lines: TStrings);
begin
  //This sub just appends the Text to the end of the txtParseTree textbox.
  Lines.Append(Text);
end;

procedure DrawReduction(TheReduction: TReduction; Indent: integer; sl: TStrings);
const
  kIndentText = '|  ';
var
  n: integer;
  IndentText: string;
begin
  {This is a simple recursive procedure that draws an ASCII version of the parse
  tree}
  IndentText := '';
  for n := 1 to Indent do
    IndentText := IndentText + kIndentText;
  //==== Display Reduction
  PrintParseTree(IndentText + '+--' + TheReduction.Parent.ToString, sl);
  //=== Display the children of the reduction
  for n := 0 to TheReduction.Count - 1 do
  begin
    case TheReduction[n].SymbolType of
      stNON_TERMINAL:
        DrawReduction(TheReduction[n].Reduction, (Indent + 1), sl);
      else
        PrintParseTree(IndentText + kIndentText + '+--' +
          TheReduction[n].Data, sl);
    end;
  end;
end;

function DrawReductionTree(TheReduction: TReduction): string;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    //This procedure starts the recursion that draws the parse tree.
    DrawReduction(TheReduction, 0, sl);
    Result := sl.Text;
  finally
    sl.Free;
  end;
end;

{ TTokenStack }

function TTokenStack.GetCount: integer;
begin
  Result := MemberList.Count;
end;

function TTokenStack.GetItem(Index: integer): TToken;
begin
  if (Index >= 0) and (Index < MemberList.Count) then
    Result := MemberList.Items[Index] as TToken
  else
    Result := nil;
end;

procedure TTokenStack.FreeOwnedTokens;
begin
  FOwnedTokens.Clear;
end;

constructor TTokenStack.Create(const fobjs: boolean);
begin
  inherited Create;
  FMemberList := TObjectList.Create(False);
  FOwnedTokens := TObjectList.Create(fobjs);
end;

destructor TTokenStack.Destroy;
begin
  MemberList.Free;
  FreeOwnedTokens;
  FOwnedTokens.Free;
  inherited Destroy;
end;

procedure TTokenStack.Clear;
begin
  MemberList.Clear;
  FreeOwnedTokens;
end;

procedure TTokenStack.Push(TheToken: TToken);
begin
  MemberList.Add(TheToken);
  if not Assigned(TheToken.FOwnerStack) then
  begin
    TheToken.FOwnerStack := self;
    FOwnedTokens.Add(TheToken);
  end;
end;

function TTokenStack.Pop: TToken;
begin
  Result := Top;
  if Assigned(Result) then
    MemberList.Delete(Count - 1);
end;

function TTokenStack.Top: TToken;
begin
  if Count <> 0 then
    Result := Items[Count - 1]
  else
    raise Exception.Create('Attempting to pop a token from an empty stack.')
end;

{ TReduction }

procedure TReduction.Execute;
begin
  Assert(True);
end;

{ TToken }

procedure TToken.SetAsSymbol(const s: TSymbol);
begin
  if not Assigned(s) then
    Exit;
  SymbolGroup := s.SymbolGroup;
  Name := s.Name;
  SymbolType := s.SymbolType;
  TableIndex := s.TableIndex;
end;

procedure TToken.SetOwnerStack(AValue: TTokenStack);
var
  too: boolean;
begin
  if FOwnerStack = AValue then
    Exit;
  with FOwnerStack.FOwnedTokens do
  begin
    too := OwnsObjects;
    OwnsObjects := False;
    Remove(self);
    OwnsObjects := too;
  end;
  FOwnerStack := AValue;
  FOwnerStack.FOwnedTokens.Add(Self);
end;

constructor TToken.Create;
begin
  inherited;
  FData := '';
  FState := 0;
end;

constructor TToken.Create(const sym: TSymbol; const dt: TReduction);
begin
  Create(sym, dt, TPosition.Create);
end;

constructor TToken.Create(const sym: TSymbol; const dt: TReduction;
  const Pos: TPosition);
begin
  Create;
  FReduction := dt;
  if Assigned(sym) then
  begin
    FName := sym.Name;
    SymbolType := sym.SymbolType;
    TableIndex := sym.TableIndex;
  end;
  FPosition := pos;
  if Assigned(dt) then
    AppendData(dt.ToString);
end;

destructor TToken.Destroy;
var
  too: boolean;
begin
  if Assigned(FOwnerStack) then
    with FOwnerStack.FOwnedTokens do
    begin
      too := OwnsObjects;
      OwnsObjects := False;
      Remove(self);
      OwnsObjects := too;
    end;
  inherited Destroy;
end;

function TToken.ToString: string;
begin
  if FText <> '' then
    Result := FText
  else
    Result := FData
end;

procedure TToken.AppendData(const s: string);
begin
  FText := FText + s;
end;

end.
