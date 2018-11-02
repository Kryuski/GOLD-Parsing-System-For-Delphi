unit Token;

{
'================================================================================
' Class Name:
'      Token
'
' Instancing:
'      Public; Creatable  (VB Setting: 5 - MultiUse)
'
' Purpose:
'       While the Symbol represents a class of terminals and nonterminals, the
'       Token represents an individual piece of information.
'       Ideally, the token would inherit directly from the Symbol Class, but do to
'       the fact that Visual Basic 5/6 does not support this aspect of Object Oriented
'       Programming, a Symbol is created as a member and its methods are mimicked.
'
' Author(s):
'      Devin Cook
'      GOLDParser@DevinCook.com
'
' Dependacies:
'      Symbol class
'
'================================================================================
 Conversion to Delphi:
      Beany
      Beany@cloud.demon.nl

 Conversion status: Done, not tested
}

interface

uses
   Symbol, Contnrs, Rule;

type

  TToken = class;

  TReduction = class
  private
    FTokens: TObjectList;
    FParentRule: TRule;
    FTag: Integer;
    function GetToken(Index: Integer): TToken;
    function GetTokenCount: Integer;
    procedure SetTag(const Value: Integer);
  public
    constructor Create(const aParentRule : TRule);
    destructor Destroy; override;
    procedure InsertToken(Index : integer; Token : TToken);
    property ParentRule: TRule read FParentRule;
    property TokenCount: Integer read GetTokenCount;
    property Tag: Integer read FTag write SetTag;
    property Tokens[Index: Integer]: TToken read GetToken;
  end;


  TTokenStack = class;

  TToken = class
  private
    FState: Integer;
    FDataVar: string;
    FReduction: TReduction;
    FParentSymbol: TSymbol;
    FOwnerStack : TTokenStack;
    function GetKind: Integer;
    function GetName: string;
    procedure SetParentSymbol(Value: TSymbol);
    procedure SetdataVar(Value: string);
    procedure SetReduction(Value: TReduction);
    function GetTableIndex: Integer;
    function GetText: string;
    procedure SetState(Value: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    property Kind : Integer read GetKind;
      // Returns an enumerated data type that denotes the symbol class of the token.
    property Name : string read GetName;
      // Returns the name of the token. This is equivalent to the parent symbol's name.
    property ParentSymbol : TSymbol read FParentSymbol write SetParentSymbol;
      // Returns a reference the token's parent symbol.
    property DataVar : string read FDataVar write SetDataVar;
     // Returns/sets the information stored in the token.
     // This can be either an standard data type or an object reference.
    property Reduction : TReduction read FReduction write SetReduction;
    property TableIndex : Integer read GetTableIndex;
      // Returns the index of the token's parent symbol in the GOLDParser object's symbol table.
    property Text : string read GetText;
      // Returns the text representation of the token's parent symbol.
      // In the case of nonterminals, the name is delimited by angle brackets,
      // special terminals are delimited by parenthesis and terminals
      // are delimited by single quotes (if special characters are present).
    property State : Integer read FState write SetState;
  end;

  TTokenStack = class
  private
    MemberList: TObjectList;
    OwnedTokens : TObjectList;
    function GetCount: Integer;
    function GetItem(Index: Integer): TToken;
    procedure FreeOwnedTokens;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Push(TheToken: TToken);
    function Pop: TToken;
    function Top: TToken;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TToken read GetItem; default;
  end;

implementation

uses
  SysUtils, Classes, Types;

{ TToken }

constructor TToken.Create;
begin
  inherited Create;
  FDataVar := '0';
end;

destructor TToken.Destroy;
begin
  FreeAndNil(FReduction);
  if Assigned(FOwnerStack) then
    FOwnerStack.OwnedTokens.Remove(Self);
  inherited Destroy;
end;

function TToken.GetKind: Integer;
begin
  Result := ParentSymbol.Kind;
end;

function TToken.GetName: string;
begin
  Result := ParentSymbol.Name;
end;

procedure TToken.SetParentSymbol(Value: TSymbol);
begin
  FParentSymbol := Value;
end;

procedure TToken.SetdataVar(Value: string);
begin
  FDataVar := Value;
end;

procedure TToken.SetReduction(Value : TReduction);
begin
  Assert(not Assigned(Reduction));
  FReduction := Value;
end;

function TToken.GetTableIndex: Integer;
begin
   Result := ParentSymbol.TableIndex;
end;

function TToken.GetText: string;
begin
   Result := ParentSymbol.Text;
end;

procedure TToken.SetState(Value: Integer);
begin
  FState := Value;
end;

{ TReduction }

constructor TReduction.Create(const aParentRule : TRule);
begin
  inherited Create;
  FTokens := TObjectList.Create(False);
  FParentRule := aParentRule;
end;

destructor TReduction.Destroy;
begin
  FTokens.Free;
  inherited Destroy;
end;

function TReduction.GetToken(Index: Integer): TToken;
begin
  Result := FTokens.items[Index] as TToken
end;

function TReduction.GetTokenCount: Integer;
begin
  Result := FTokens.Count;
end;

procedure TReduction.InsertToken(Index: integer; Token: TToken);
begin
  FTokens.Insert(Index, Token);
end;

procedure TReduction.SetTag(const Value: Integer);
begin
  FTag := Value;
end;

{ TReduction }

constructor TTokenStack.Create;
begin
  inherited Create;
  MemberList := TObjectList.Create(False);
  OwnedTokens := TObjectList.Create(False);
end;

destructor TTokenStack.Destroy;
begin
  MemberList.Free;
  FreeOwnedTokens;
  OwnedTokens.Free;
  inherited Destroy;
end;

function TTokenStack.GetCount: Integer;
begin
  Result := MemberList.Count;
end;

procedure TTokenStack.Clear;
begin
  MemberList.Clear;
  FreeOwnedTokens;
end;

function TTokenStack.GetItem(Index: Integer): TToken;
begin
  if (Index >= 0) and (Index < MemberList.Count)
  then Result := MemberList.Items[Index] as TToken
  else Result := nil;
end;

procedure TTokenStack.Push(TheToken: TToken);
begin
  MemberList.Add(TheToken);
  if not Assigned(TheToken.FOwnerStack) then begin
    TheToken.FOwnerStack := Self;
    OwnedTokens.Add(TheToken);
  end;
end;

function TTokenStack.Pop: TToken;
begin
  Result := Top;
  if Assigned(Result) then MemberList.Delete(Count - 1);
end;

function TTokenStack.Top: TToken;
begin
  Result := Items[Count - 1];
end;

procedure TTokenStack.FreeOwnedTokens;
begin
  while OwnedTokens.Count > 0 do OwnedTokens[0].Free;
  OwnedTokens.Clear;
end;

end.
