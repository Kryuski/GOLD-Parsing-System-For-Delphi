{
Copyright © 2015 Theodore Tsirpanis
This software is provided 'as-is', without any expressed or implied warranty. In no event will the author(s) be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose. If you use this software in a product, an acknowledgment in the product documentation would be deeply appreciated but is not required.

In the case of the GOLD Parser Engine source code, permission is granted to anyone to alter it and redistribute it freely, subject to the following restrictions:

The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
This notice may not be removed or altered from any source distribution
}
unit Production;

interface

uses
  Classes, SysUtils, Generics.Collections, Symbol, gold_types;

type

  { TProduction }

  TProduction = class
  private
    FHead: TSymbol;
    FHandle: TSymbolList;
    FTableIndex: integer;
  public
    constructor Create(const hd: TSymbol; const ti: integer);
    destructor Destroy; override;
    function HasOneNonTerminal: boolean;
    function ToString: string; override;
    property Head: TSymbol read FHead write FHead;
    property Handle: TSymbolList read FHandle;
  end;

  TProductionList = TList<TProduction>;

implementation

{ TProduction }

constructor TProduction.Create(const hd: TSymbol; const ti: integer);
begin
  FHead := hd;
  FTableIndex := ti;
  FHandle := TSymbolList.Create;
end;

destructor TProduction.Destroy;
begin
  FHandle.Free;
  inherited Destroy;
end;

function TProduction.HasOneNonTerminal: boolean;
begin
  {$B+}
  Result := (FHandle.Count = 1) and (FHandle.Items[0].SymbolType = stNON_TERMINAL);
end;

function TProduction.ToString: string;
begin
  Result := FHead.ToString + ' ::= ' + FHandle.ToString;
end;

end.
