unit Rule;

{
'================================================================================
' Class Name:
'      Rule
'
' Instancing:
'      Public; Non-creatable  (VB Setting: 2- PublicNotCreatable)
'
' Purpose:
'      The Rule class is used to represent the logical structures of the grammar.
'      Rules consist of a head containing a nonterminal followed by a series of
'      both nonterminals and terminals.
'
' Author(s):
'      Devin Cook
'      GOLDParser@DevinCook.com
'
' Dependacies:
'      Symbol Class, SymbolList Class
'
'================================================================================
 Conversion to Delphi:
      Beany
      Beany@cloud.demon.nl

 Conversion status: Done, not tested
}

interface

uses
   Classes, SysUtils, Symbol, contnrs;

type

   TRule = class
   private
     FRuleNonterminal: TSymbol;
     FRuleSymbols: TObjectList;
     FTableIndex: Integer;
     function GetSymbolCount: Integer;
     function GetNonterminal: TSymbol;
     function GetSymbols(Index: Integer): TSymbol;
   public
     constructor Create(aTableIndex : integer; aNonTerminal : TSymbol);
     destructor Destroy; override;
     procedure AddItem(Item: TSymbol);
     function Name: string;
     function Definition: string;
     function ContainsOneNonTerminal: Boolean;
     function Text: String;
     // Returns the Backus-Noir representation of the rule.
     property SymbolCount: Integer read GetSymbolCount;
     // Returns the number of symbols that consist the body (right-hand-side) of the rule.
     property RuleNonterminal: TSymbol read GetNonterminal;
     // Returns the head symbol of the rule.
     property TableIndex: Integer read FTableIndex;
     // Returns the index of the rule in the GOLDParser object's Rule Table.
     property Symbols[Index: Integer]: TSymbol read GetSymbols;
     // Returns one of the symbols that consist the body of the rule.
     // The index of the symbol ranges from 0 to SymbolCount -1
  end;

  TRuleTable = class
  private
    FList : TObjectList;
    function GetCount: integer;
    function GetItem(Index: integer): TRule;
    procedure SetItem(Index: integer; const Value: TRule);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(Value : TObject);
    procedure Clear;

    property Count : integer read GetCount;
    property Items[Index : integer] : TRule read GetItem write SetItem; default;
  end;

implementation

constructor TRule.Create(aTableIndex : integer; aNonTerminal : TSymbol);
begin
  inherited Create;
  FRuleSymbols := TObjectList.Create(False);
  FTableIndex := aTableIndex;
  FRuleNonterminal := aNonTerminal;
end;

destructor TRule.Destroy;
begin
  FRuleSymbols.Free;
  inherited;
end;

function TRule.GetSymbolCount: Integer;
begin
  Result := FRuleSymbols.Count;
end;

function TRule.Name: string;
begin
  Result := '<' + FRuleNonterminal.Name + '>';
end;

function TRule.GetNonterminal: TSymbol;
begin
  Result := FRuleNonterminal;
end;

procedure TRule.AddItem(Item: TSymbol);
begin
  FRuleSymbols.Add(Item);
end;

function TRule.Definition: string;
var i : integer;
begin
  Result := '';
  for i := 0 to SymbolCount - 1 do Result := Result + Symbols[i].Text + ' ';
  Result := Trim(Result);
end;

function TRule.ContainsOneNonTerminal: Boolean;
begin
  Result := (SymbolCount = 1) and (Symbols[0].Kind = SymbolTypeNonterminal);
end;

function TRule.GetSymbols(Index: Integer): TSymbol;
begin
  Result := FRuleSymbols[Index] as TSymbol;
end;

function TRule.Text: String;
begin
  Result := Name + ' ::= ' + Definition;
end;

{ TRuleTable }

procedure TRuleTable.Add(Value: TObject);
begin
  FList.Add(Value);
end;

procedure TRuleTable.Clear;
begin
  FList.Clear;
end;

constructor TRuleTable.Create;
begin
  inherited;
  FList := TObjectList.Create(True);
end;

destructor TRuleTable.Destroy;
begin
  FList.Free;
  inherited;
end;

function TRuleTable.GetCount: integer;
begin
  Result := FList.Count;
end;

function TRuleTable.GetItem(Index: integer): TRule;
begin
  Result := FList[Index] as TRule;
end;

procedure TRuleTable.SetItem(Index: integer; const Value: TRule);
begin
  if Index >= Count then FList.Count := Index + 1;
  if Assigned(Items[Index]) then Items[Index].Free;
  FList[Index] := Value;
end;

end.
