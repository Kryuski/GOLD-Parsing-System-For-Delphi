unit GrammarReader;

interface

uses
   Classes, GOLDParser;

const

   EntryContentEmpty = 69;
   EntryContentInteger = 73;
   EntryContentString = 83;
   EntryContentBoolean = 66;
   EntryContentByte = 98;

   RecordIdParameters  = 80;   //P
   RecordIdTableCounts = 84;   //T
   RecordIdInitial     = 73;   //I
   RecordIdSymbols     = 83;   //S
   RecordIdCharSets    = 67;   //C
   RecordIdRules       = 82;   //R
   RecordIdDFAStates   = 68;   //D
   RecordIdLRTables    = 76;   //L
   RecordIdComment     = 33;   //!

type
  TGrammarReader = class
  private
    FBufferPos: Integer;
    FBuffer: TArray<Byte>;
    FCurrentRecord: Variant;
    FEntryPos: Integer;
    FEntryCount: Integer;
    FStartSymbol: Integer;
    FParser: TGoldParser;
    function ReadUniString: string;
    function ReadInt16: Integer;
    function ReadByte: Byte;
    function ReadEntry: Variant;
    function OpenFile(const FileName: string): Boolean;
    function OpenStream(const Stream: TStream): Boolean;
  protected
    function DoLoadTables: Boolean;
  public
    constructor Create(aParser: TGoldParser);
    destructor Destroy; override;
    function GetNextRecord: Boolean;
    function RetrieveNext: Variant;
    function LoadTables(const FileName: string): Boolean; overload;
    function LoadTables(const Stream: TStream): Boolean; overload;
    property Buffer: TArray<Byte> read FBuffer;
    property StartSymbol: Integer read FStartSymbol write FStartSymbol;
    property Parser: TGOLDParser read FParser;
  end;

implementation

uses
  SysUtils, Variants, Symbol, Rule, FAState, LRAction;

const
  FHeader: string = 'GOLD Parser Tables/v1.0';

constructor TGrammarReader.Create(aParser: TGoldParser);
begin
  inherited Create;
  FParser := aParser;
end;

destructor TGrammarReader.Destroy;
begin
  inherited Destroy;
end;

function TGrammarReader.OpenFile(const FileName: string): Boolean;
var FS: TFileStream;
begin
  try
    FS := TFileStream.Create(Filename, fmOpenRead);
    try
      SetLength(FBuffer, FS.Size);
      FS.ReadBuffer(FBuffer[1], FS.Size);
      Result := True;
      FBufferPos := 1;
    finally
      FS.Free;
    end;
  except
    Result := False;
    FBufferPos := -1;
  end;
end;

function TGrammarReader.GetNextRecord: Boolean;
var
  TypeOfRecord: AnsiChar;
  i, Entries: Integer;
begin
  Result := False;
  TypeOfRecord := AnsiChar(ReadByte);
   //Structure below is ready for future expansion
  case TypeOfRecord of
  'M': begin
         //Read the number of entry's
         Entries := ReadInt16;
         VarClear(FCurrentRecord);
         FCurrentRecord := VarArrayCreate([1, Entries], varVariant);
         FEntryCount := Entries;
         FEntryPos := 1;
         for i := 1 to Entries do FCurrentRecord[i] := ReadEntry;
         Result := True;
       end;
  end;
end;

function TGrammarReader.ReadUniString: string;
var
  uchr: Integer;
begin
  uchr := ReadInt16;
  while (uchr <> 0) do begin
    Result := Result + chr(uchr);
    uchr := ReadInt16;
  end;
end;

function TGrammarReader.ReadInt16: Integer;
begin
  Result := ord(FBuffer[FBufferPos]) + ord(FBuffer[FBufferPos + 1]) * 256;
  FBufferPos := FBufferPos + 2;
end;

function TGrammarReader.ReadByte: Byte;
begin
  Result := FBuffer[FBufferPos];
  Inc(FBufferPos);
end;

function TGrammarReader.ReadEntry: Variant;
var
  EntryType: Byte;
begin
  EntryType := ReadByte;
  case EntryType of
    EntryContentEmpty: Result := varEmpty;
    EntryContentInteger: Result := ReadInt16;
    EntryContentBoolean: Result := ReadByte <> 0;
    EntryContentString: Result := ReadUniString;
    EntryContentByte: Result := ReadByte;
  end;
end;

function TGrammarReader.RetrieveNext: Variant;
begin
  if FEntryPos <= FEntryCount then begin
    Result := FCurrentRecord[FEntryPos];
    Inc(FEntryPos);
  end else
    Result := varEmpty;
end;

function TGrammarReader.DoLoadTables: Boolean;
var
  Id: Byte;
  iDummy1, iDummy2, iDummy3, i: Integer;
  strDummy: string;
  NewSymbol: TSymbol;
  NewRule: TRule;
  NewFAState: TFAState;
  bAccept: Boolean;
  NewActionTable: TLRActionTable;
begin
  Parser.VariableList.Add('Name', '');
  Parser.VariableList.Add('Version', '');
  Parser.VariableList.Add('Author', '');
  Parser.VariableList.Add('About', '');
  Parser.VariableList.Add('Case Sensitive', '');
  Parser.VariableList.Add('Start Symbol', '');

  Result := False;

  if FHeader = ReadUniString then begin
    while (FBufferPos < Length(FBuffer)) do begin
      Result := GetNextRecord;
      Id := RetrieveNext;
      case Id of
        RecordIdParameters: begin
          Parser.VariableList.Value['Name'] := RetrieveNext;
          Parser.VariableList.Value['Version'] := RetrieveNext;
          Parser.VariableList.Value['Author'] := RetrieveNext;
          Parser.VariableList.Value['About'] := RetrieveNext;
          Parser.VariableList.Value['Case Sensitive'] := RetrieveNext;
          Parser.VariableList.Value['Start Symbol'] := RetrieveNext;
          FStartSymbol := StrToInt(Parser.VariableList.Value['Start Symbol']);
        end;
        RecordIdTableCounts: begin
          RetrieveNext; // for i := 0 to RetrieveNext - 1 do Parser.SymbolTable.Add(nil);
          for i := 0 to RetrieveNext do Parser.CharacterSetTable.Add('');
          RetrieveNext; // for i := 0 to RetrieveNext do Parser.RuleTable.Add(nil);
          RetrieveNext; // for i := 0 to RetrieveNext do Parser.DFA.Add(nil);
          RetrieveNext; // for i := 0 to RetrieveNext do Parser.ActionTable.Add(nil, 0, 0);
        end;
        RecordIdInitial: begin
          Parser.InitialDFAState := RetrieveNext;
          Parser.InitialLALRState := RetrieveNext;
        end;
        RecordIdSymbols: begin
          iDummy1 := RetrieveNext;
          strDummy := RetrieveNext;
          iDummy2 := RetrieveNext;

          NewSymbol := TSymbol.Create(iDummy1, strDummy, iDummy2);

          RetrieveNext;
          Parser.SymbolTable.Items[NewSymbol.TableIndex] := NewSymbol;
        end;
        RecordIdCharSets: begin
          iDummy1 := RetrieveNext;
          Parser.CharacterSetTable.Strings[iDummy1] := RetrieveNext;
        end;
        RecordIdRules: begin
          iDummy1 := RetrieveNext;
          NewRule := TRule.Create(iDummy1, Parser.SymbolTable.Items[RetrieveNext]);
          RetrieveNext;
          while FEntryPos <= FEntryCount do
            NewRule.AddItem(Parser.SymbolTable.Items[RetrieveNext]);
          Parser.RuleTable.Items[NewRule.TableIndex] := NewRule;
        end;
        RecordIdDFAStates: begin
          NewFAState := TFAState.Create;
          iDummy1 := RetrieveNext;
          bAccept := RetrieveNext;
          if bAccept then NewFAState.AcceptSymbol := RetrieveNext
          else begin
            NewFAState.AcceptSymbol := -1;
            RetrieveNext;
          end;
          RetrieveNext;
          while FEntryPos <= FEntryCount do begin
            strDummy := RetrieveNext;
            iDummy2 := RetrieveNext;
            NewFAState.AddEdge(strDummy, iDummy2);
            RetrieveNext;
          end;
          Parser.DFA.Items[iDummy1] := NewFAState;
        end;
        RecordIdLRTables: begin
          NewActionTable := TLRActionTable.Create;
          i := RetrieveNext;
          RetrieveNext;
          while FEntryPos <= FEntryCount do begin
            iDummy1 := RetrieveNext;
            iDummy2 := RetrieveNext;
            iDummy3 := RetrieveNext;
            NewActionTable.Add(Parser.SymbolTable[iDummy1], iDummy2, iDummy3);
            RetrieveNext;
          end;
          Parser.ActionTables.Items[i] := NewActionTable;
        end;
      end;
    end;
  end;
  Parser.VariableList.Value['Start Symbol'] := TSymbol(Parser.SymbolTable.Items[StrToInt(Parser.VariableList.Value['Start Symbol'])]).Name;
end;

function TGrammarReader.LoadTables(const Stream: TStream): Boolean;
begin
  Result := OpenStream(Stream) and DoLoadTables;
end;

function TGrammarReader.LoadTables(const FileName: string): Boolean;
begin
  Result := OpenFile(FileName) and DoLoadTables;
end;

function TGrammarReader.OpenStream(const Stream: TStream): Boolean;
begin
  try
    SetLength(FBuffer, Stream.Size);
    Stream.ReadBuffer(FBuffer[1], Stream.Size);

    Result := True;
    FBufferPos := 1;
  except
    Result := False;
    FBufferPos := -1;
  end;
end;

end.

