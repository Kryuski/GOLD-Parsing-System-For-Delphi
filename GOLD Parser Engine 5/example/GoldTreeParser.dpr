program GoldTreeParser;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Classes,
  SysUtils,
  parser in '..\parser.pas',
  gold_types in '..\gold_types.pas',
  token in '..\token.pas',
  cgt in '..\cgt.pas',
  characterset in '..\characterset.pas',
  fastate in '..\fastate.pas',
  symbol in '..\symbol.pas',
  production in '..\production.pas',
  scope in '..\scope.pas',
  variable in '..\variable.pas';

const
  HelpStr = 'Usage: GoldTreeParser [grammar_file] [source_file] [output_file]';

type

  { TGOLDParser }

  TGOLDParser = class(TAbstractGOLDParser)
  private
    ftree: string;
    FLog: TStrings;
    function GetLog: string;
    procedure AddLog(const s: string; const p: TPosition);
  public
    constructor Create; overload;
    constructor Create(const grm_file, src_file: string); overload;
    property Tree: string read ftree;
    property Log: string read GetLog;
  end;

  procedure TGOLDParser.AddLog(const s: string; const p: TPosition);
  begin
    FLog.Add(s + ' ' + p.ToString);
  end;

  function TGOLDParser.GetLog: string;
  begin
    Result := FLog.Text;
  end;

  constructor TGOLDParser.Create;
  begin
    Create(ParamStr(1), ParamStr(2));
  end;

  constructor TGOLDParser.Create(const grm_file, src_file: string);
  var
    Done: boolean;
    Res: TParseMessage;
    i: integer;
    s: string;
  begin
    inherited Create;
    Done := False;
    ftree := '';
    FLog := TStringList.Create;
    LoadTables(grm_file);
    OpenFile(src_file);
    while not Done do
    begin
      Res := Parse;
      Done := res in [pmACCEPT..pmINTERNAL_ERROR];
      case Res of
        pmTOKEN_READ: AddLog('Token read: ' + CurrentToken.Name +
            ', ' + CurrentToken.Data, CurrentToken.Position);
        pmREDUCTION: AddLog('Reduction: ' + CurrentReduction.Parent.ToString,
            CurrentPosition);
        pmACCEPT:
        begin
          AddLog('Grammar accepted successfully.', CurrentPosition);
          ftree := DrawReductionTree(CurrentReduction);
        end;
        pmNOT_LOADED_ERROR: AddLog('Grammar is not loaded.', CurrentPosition);
        pmLEXICAL_ERROR: AddLog('Lexical error: Cannot recognize token ' +
            CurrentToken.Data, CurrentToken.Position);
        pmSYNTAX_ERROR:
        begin
          s := '';
          for i := 0 to ExpectedSymbols.Count - 1 do
            s := s + ', ' + ExpectedSymbols[i].Name;
          AddLog(Format('Syntax error: Expected one of these tokens: %s but got %s.',
            [s, QuotedStr(CurrentToken.Name)]), CurrentPosition);
        end;
        pmGROUP_ERROR: AddLog('Error: Unexpected end of file.', CurrentPosition);
        pmINTERNAL_ERROR: AddLog('Internal Error: Something is bad, very bad',
            CurrentPosition);
      end;
    end;
  end;

var
  gp: TGOLDParser;
  sl: TStringList;

begin
{$WARN SYMBOL_PLATFORM OFF}
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
{$WARN SYMBOL_PLATFORM ON}
  try
    {$IF DECLARED (HeapTrc)}
    if FileExists('goldtrcc.txt') then
      DeleteFile('goldtrcc.txt');
    SetHeapTraceOutPut('goldtrcc.txt');
    {$ENDIF}
    if Paramcount < 3 then begin
      Write(HelpStr);
      Exit;
    end;
    if not FileExists(ParamStr(1)) and not FileExists(ParamStr(2)) then begin
      Write('Some files do not exist');
      Exit;
    end;
    gp := TGOLDParser.Create;
    sl := TStringList.Create;
    try
      sl.Add('###################PARSE_TREE###################');
      sl.Add(gp.Tree);
      sl.Add('#######################LOG######################');
      sl.Add(gp.Log);
      sl.SaveToFile(ParamStr(3));
      Write(sl.Text);
    finally
      sl.Free;
      gp.Free;
    end;
  except
    on E: Exception do begin
      Writeln(E.ClassName, ': ', E.Message);
      Writeln('Press Enter to continue...');
      ReadLn;
    end;
  end;
end.
