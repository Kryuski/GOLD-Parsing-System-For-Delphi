unit FAState;

{
'================================================================================
' Class Name:
'      FAState
'
' Instancing:
'      Private; Internal  (VB Setting: 1 - Private)
'
' Purpose:
'      Represents a state in the Deterministic Finite Automata which is used by
'      the tokenizer.
'
' Author(s):
'      Devin Cook
'      GOLDParser@DevinCook.com
'
' Dependacies:
'      FAEdge
'
'================================================================================
 Conversion to Delphi:
      Beany
      Beany@cloud.demon.nl

 Conversion status: Done, not tested
}

interface

uses
   Classes, SysUtils, Dialogs, contnrs;

type

  TFAEdge = class
  private
    FCharacters: Integer;
    FTargetIndex: Integer;
    procedure SetCharacters(const Value: integer);
    procedure SetTargetIndex(const Value: integer);
  public
    property Characters : integer read FCharacters write SetCharacters;
    property TargetIndex : integer read FTargetIndex write SetTargetIndex;
  end;

  TFAState = class
  private
    FEdges: TObjectList;
    FAcceptSymbol: Integer;
    function GetEdgeCount: Integer;
    function GetEdge(Index: Integer): TFAEdge;
    procedure SetAcceptSymbol(const Value: Integer);
    procedure Add(Characters, Target : integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddEdge(Characters: string; Target: Integer);

    property AcceptSymbol: Integer read FAcceptSymbol write SetAcceptSymbol;
    property EdgeCount: Integer read GetEdgeCount;
    property Edges[Index : integer] : TFAEdge read GetEdge; default;
  end;

  TFStateTable = class
  private
    FList : TObjectList;
    function GetCount: integer;
    function GetItem(Index: integer): TFAState;
    procedure SetItem(Index: integer; const Value: TFAState);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(Value : TObject);

    property Count : integer read GetCount;
    property Items[Index : integer] : TFAState read GetItem write SetItem; default;
  end;

implementation

constructor TFAState.Create;
begin
  inherited Create;
  FEdges := TObjectList.Create(True);
end;

destructor TFAState.Destroy;
begin
  FEdges.Free;
  inherited Destroy;
end;

procedure TFAState.AddEdge(Characters: string; Target: Integer);
var n: Integer;
begin
  if Characters = '' then Add(0, Target)
  else begin
    for n := 0 to EdgeCount - 1 do
      if Edges[n].TargetIndex = Target then begin
        Edges[n].Characters := Edges[n].Characters + StrToIntDef(Characters, 0);
        Exit;
      end;
    Add(StrToIntDef(Characters, 0), Target);
  end;
end;

function TFAState.GetEdgeCount: Integer;
begin
   Result := FEdges.Count;
end;

function TFAState.GetEdge(Index: Integer): TFAEdge;
begin
  Result := FEdges[Index] as TFAEdge;
end;

procedure TFAState.SetAcceptSymbol(const Value: Integer);
begin
  FAcceptSymbol := Value;
end;

procedure TFAState.Add(Characters, Target: integer);
begin
  FEdges.Add(TFAEdge.Create);
  Edges[EdgeCount - 1].Characters := Characters;
  Edges[EdgeCount - 1].TargetIndex := Target;
end;

{ TFAEdge }

procedure TFAEdge.SetCharacters(const Value: integer);
begin
  FCharacters := Value;
end;

procedure TFAEdge.SetTargetIndex(const Value: integer);
begin
  FTargetIndex := Value;
end;


{ TFStateTable }

procedure TFStateTable.Add(Value: TObject);
begin
  FList.Add(Value);
end;

constructor TFStateTable.Create;
begin
  inherited;
  FList := TObjectList.Create(True);
end;

destructor TFStateTable.Destroy;
begin
  FList.Free;
  inherited;
end;

function TFStateTable.GetCount: integer;
begin
  Result := FList.Count;
end;

function TFStateTable.GetItem(Index: integer): TFAState;
begin
  Result := FList[Index] as TFAState;
end;

procedure TFStateTable.SetItem(Index: integer; const Value: TFAState);
begin
  if Index >= Count then FList.Count := Index + 1;
  if Assigned(Items[Index]) then Items[Index].Free;
  FList[Index] := Value;
end;

end.
