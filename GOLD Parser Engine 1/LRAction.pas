unit LRAction;

{
'================================================================================
' Class Name:
'      LRAction
'
' Instancing:
'      Private; Internal  (VB Setting: 1 - Private)
'
' Purpose:
'      This class represents an action in a LALR State. There is one and only one
'      action for any given symbol.
'
' Author(s):
'      Devin Cook
'      GOLDParser@DevinCook.com
'
' Dependacies:
'      (None)
'
'================================================================================
 Conversion to Delphi:
      Beany
      Beany@cloud.demon.nl

 Conversion status: Done, not tested
}

interface

uses
   Symbol, Contnrs;

const

   ActionShift = 1;       //Shift a symbol and goto a state
   ActionReduce = 2;      //Reduce by a specified rule
   ActionGoto = 3;        //Goto to a state on reduction
   ActionAccept = 4;      //Input successfully parsed
   ActionError = 5;       //Programmars see this often!

type

  TLRAction = class
  private
    FSymbol: TSymbol;
    FAction: Integer;
    FValue: Integer;
    function GetSymbol: TSymbol;
    function GetSymbolIndex: Integer;
  public
    property Value: Integer read FValue;
    property Action: Integer read FAction;
    property Symbol: TSymbol read GetSymbol;
    property SymbolIndex: Integer read GetSymbolIndex;
  end;

  TLRActionTable = class
  private
    FList: TObjectList;
    function GetCount: integer;
    function GetItem(Index: integer): TLRAction;
    procedure SetItem(Index: integer; const Value: TLRAction);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(TheSymbol: TSymbol; Action: Integer; Value: Integer);
    function ActionIndexForSymbol(SymbolIndex: Integer): Integer;

    property Count: integer read GetCount;
    property Items[Index: integer]: TLRAction read GetItem write SetItem; default;
  end;

  TLRActionTables = class
  private
    FList: TObjectList;
    function GetCount: integer;
    function GetItem(Index: integer): TLRActionTable;
    procedure SetItem(Index: integer; const Value: TLRActionTable);
  public
    constructor Create;
    destructor Destroy; override;

    property Count: integer read GetCount;
    property Items[Index: integer]: TLRActionTable read GetItem write SetItem; default;
  end;

implementation

uses
  Classes;

function TLRAction.GetSymbol: TSymbol;
begin
  Result := FSymbol;
end;

function TLRAction.GetSymbolIndex: Integer;
begin
  Result := FSymbol.TableIndex;
end;

{ TLRActionTable }

function TLRActionTable.ActionIndexForSymbol(SymbolIndex: Integer): Integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to Count - 1 do
    if Items[i].Symbol.TableIndex = SymbolIndex then begin
      Result := i;
      Exit;
    end;
end;

procedure TLRActionTable.Add(TheSymbol: TSymbol; Action: Integer; Value: Integer);
begin
  FList.Add(TLRAction.Create);
  Items[Count - 1].FSymbol := TheSymbol;
  Items[Count - 1].FAction := Action;
  Items[Count - 1].FValue := Value;
end;

constructor TLRActionTable.Create;
begin
  inherited;
  FList := TObjectList.Create(True);
end;

destructor TLRActionTable.Destroy;
begin
  FList.Free;
  inherited;
end;

function TLRActionTable.GetCount: integer;
begin
  Result := FList.Count;
end;

function TLRActionTable.GetItem(Index: integer): TLRAction;
begin
  Result := FList[Index] as TLRAction;
end;

procedure TLRActionTable.SetItem(Index: integer; const Value: TLRAction);
begin
  if Index >= Count then
    FList.Count := Index + 1;
  if Assigned(Items[Index]) then
    Items[Index].Free;
  FList[Index] := Value;
end;

{ TLRActionTables }

constructor TLRActionTables.Create;
begin
  inherited;
  FList := TObjectList.Create(True);
end;

destructor TLRActionTables.Destroy;
begin
  FList.Free;
  inherited;
end;

function TLRActionTables.GetCount: integer;
begin
  Result := FList.Count;
end;

function TLRActionTables.GetItem(Index: integer): TLRActionTable;
begin
  Result := FList[Index] as TLRActionTable;
end;

procedure TLRActionTables.SetItem(Index: integer; const Value: TLRActionTable);
begin
  if Index >= Count then
    FList.Count := Index + 1;
  if Assigned(Items[Index]) then
    Items[Index].Free;
  FList[Index] := Value;
end;

end.
