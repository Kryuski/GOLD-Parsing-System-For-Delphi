{
Copyright © 2015 Theodore Tsirpanis
This software is provided 'as-is', without any expressed or implied warranty. In no event will the author(s) be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose. If you use this software in a product, an acknowledgment in the product documentation would be deeply appreciated but is not required.

In the case of the GOLD Parser Engine source code, permission is granted to anyone to alter it and redistribute it freely, subject to the following restrictions:

The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
This notice may not be removed or altered from any source distribution
}
unit CGT;

interface

uses
  Classes, SysUtils, gold_types;

const
  RECORD_CONTENT_MULTI = 77;

type
  TEntry = record
    EntryType: TEntryType;
    AsBool: boolean;
    AsByte: byte;
    AsUInt16: word;
    AsString: UnicodeString;
  end;

  { TCGT }

  TCGT = class
  private
    eofReached: boolean;
    FClosed: boolean;
    fEntriesRead, fEntryCount: integer;
    Hdr: string;
    stream: TMemoryStream;
    function RawReadCString: UnicodeString;
    function RawReadUInt16: word;
    function ReadByte: byte;
    function RetrieveEntry(const tp: TEntryType): TEntry; overload;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Close;
    function GetNextRecord: boolean;
    function IsRecordComplete: boolean;
    procedure Open(const inps: TStream); overload;
    procedure Open(const inps: string); overload;
    function RetrieveBoolean: boolean;
    function RetrieveByte: byte;
    function RetrieveInteger: word;
    function RetrieveString: UnicodeString;
    function RetrieveEntry: TEntry; overload;
    property Closed: boolean read FClosed;
    property EOF: boolean read eofReached;
    property EntryCount: integer read fEntryCount;
    property EntriesRead: integer read fEntriesRead;
    property Header: string read Hdr;
  end;

implementation

{ TCGT }

function TCGT.RetrieveEntry(const tp: TEntryType): TEntry;
begin
  Result.AsUInt16 := 0;
  Result := RetrieveEntry();
  if Result.EntryType <> tp then
    raise EInOutError.Create('Invalid entry type');
end;

function TCGT.RawReadCString: UnicodeString;
var
  c: WideChar;
begin
  Result := '';
  c := WideChar(RawReadUInt16);
  while ((not EOF) and (c <> #0)) do
  begin
    Result := Result + c;
    c := WideChar(RawReadUInt16);
  end;
end;

function TCGT.RawReadUInt16: word;
var
  b0: byte;
  b1: byte;
begin
  b0 := ReadByte;
  b1 := ReadByte;
  Result := (b1 shl 8) + b0
end;

function TCGT.ReadByte: byte;
begin
  Result := 0;
  eofReached := stream.Read(Result, 1) = 0;
end;

constructor TCGT.Create;
begin
  eofReached := True;
  stream := TMemoryStream.Create;
end;

destructor TCGT.Destroy;
begin
  stream.Free;
  inherited Destroy;
end;

procedure TCGT.Close;
begin
  eofReached := True;
  stream.Clear;
end;

function TCGT.GetNextRecord: boolean;
var
  id: byte;
begin
  while fEntriesRead < fEntryCount do
    RetrieveEntry;
  id := ReadByte;
  if id = RECORD_CONTENT_MULTI then
  begin
    fEntriesRead := 0;
    fEntryCount := RawReadUInt16;
    Result := True;
  end
  else
    Result := False;
end;

function TCGT.IsRecordComplete: boolean;
begin
  Result := EntriesRead >= EntryCount;
end;

procedure TCGT.Open(const inps: TStream);
begin
  if not Assigned(inps) then
    Exit;
  FClosed := False;
  stream.Clear;
  fEntryCount := 0;
  fEntriesRead := 0;
  stream.LoadFromStream(inps);
  hdr := RawReadCString;
end;

procedure TCGT.Open(const inps: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(inps, fmOpenRead);
  try
    Open(fs)
  finally
    fs.Free;
  end;
end;

function TCGT.RetrieveBoolean: boolean;
begin
  Result := RetrieveEntry(etBOOLEAN).AsBool;
end;

function TCGT.RetrieveByte: byte;
begin
  Result := RetrieveEntry(etBYTE).AsByte;
end;

function TCGT.RetrieveInteger: word;
begin
  Result := RetrieveEntry(etUINT16).AsUInt16;
end;

function TCGT.RetrieveString: UnicodeString;
begin
  Result := RetrieveEntry(etSTRING).AsString;
end;

function TCGT.RetrieveEntry: TEntry;
begin
  FillChar((@Result)^, SizeOf(Result), #0);
  if fEntriesRead < EntryCount then
  begin
    Inc(fEntriesRead);
    Result.EntryType := TEntryType(ReadByte);
    case Result.EntryType of
      etBOOLEAN: Result.AsBool := ReadByte = 1;
      etUINT16: Result.AsUInt16 := RawReadUInt16;
      etSTRING: Result.AsString := RawReadCString;
      etBYTE: Result.AsByte := ReadByte;
    end;
  end
  else
    Result.EntryType := etERROR;
end;

end.
