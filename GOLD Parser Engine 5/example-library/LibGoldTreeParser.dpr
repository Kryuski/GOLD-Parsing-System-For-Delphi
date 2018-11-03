library LibGoldTreeParser;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  Parser,
  gold_types,
  Token;

{$R *.res}

type

  { TGOLDParser }

  TGOLDParser = class(TAbstractGOLDParser)
    fSuccess: boolean;
  public
    constructor Create(const grm_file, src_file: string);
    property Success: boolean read fSuccess;
  end;

  constructor TGOLDParser.Create(const grm_file, src_file: string);
  var
    Done: boolean;
    Res: TParseMessage;
  begin
    inherited Create;
    LoadTables(grm_file);
    OpenFile(src_file);
    repeat
      Res := Parse;
      Done := Res in [pmACCEPT..pmINTERNAL_ERROR];
    until Done;
    fSuccess := Res = pmAccept;
  end;

  function ParseFile(const egtFile, srcFile: PChar): HRESULT; stdcall;
  var
    gp: TGOLDParser;
  begin
    gp := TGOLDParser.Create(string(egtFile), string(srcFile));
    try
      if gp.Success then
        Result := 0
      else
        Result := 1;
    finally
      gp.Free;
    end;
  end;

exports ParseFile;

end.
