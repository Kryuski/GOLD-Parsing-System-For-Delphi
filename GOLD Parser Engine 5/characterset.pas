{
Copyright © 2015 Theodore Tsirpanis
This software is provided 'as-is', without any expressed or implied warranty. In no event will the author(s) be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose. If you use this software in a product, an acknowledgment in the product documentation would be deeply appreciated but is not required.

In the case of the GOLD Parser Engine source code, permission is granted to anyone to alter it and redistribute it freely, subject to the following restrictions:

The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
This notice may not be removed or altered from any source distribution
}
unit CharacterSet;

interface

uses
  Classes, SysUtils, Math, GContnrs, Generics.Collections, gold_types;

type

  { TCharacterRange }

  TCharacterRange = record
  private
    FChrSrt: UnicodeString;
    FStart, FEnd: WideChar;
  public
    class function Create(const s: UnicodeString): TCharacterRange; overload; static;
    class function Create(const s, e: WideChar): TCharacterRange; overload; static;
    property CharSet: UnicodeString read FChrSrt;
    property Start: WideChar read FStart;
    property _End: WideChar read FEnd;
  end;

  TCSet = TGenVector<TCharacterRange>;

  { TCharacterSet }

  TCharacterSet = class(TCSet)
    function Contains(const code: WideChar): boolean;
  end;

  TCharacterSetList = TList<TCharacterSet>;

implementation

{ TCharacterRange }

class function TCharacterRange.Create(const s: UnicodeString): TCharacterRange;
begin
  Result.FChrSrt := s;
  Result.FStart := #0;
  Result.FEnd := #0;
end;

class function TCharacterRange.Create(const s, e: WideChar): TCharacterRange;
begin
  Result.FChrSrt := '';
  Result.FStart := WideChar(Min(Ord(s), Ord(e)));
  Result.FEnd := WideChar(Max(Ord(s), Ord(e)));
end;


{ TCharacterSet }

function TCharacterSet.Contains(const code: WideChar): boolean;
var
  cr: TCharacterRange;
begin
  Result := False;
  for cr in self do
    if Result then
      Exit
    else
    if cr.CharSet <> '' then
      Result := Pos(code, cr.CharSet) <> 0
    else
      Result := InRange(Ord(Code), Ord(cr.Start), Ord(cr._End));
end;

end.
