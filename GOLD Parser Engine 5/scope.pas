{
  This software is provided 'as-is', without any expressed or implied warranty.
  In no event will the author(s) be held liable for any damages arising from
  the use of this software. Permission is granted to anyone to use this software
  for any purpose. If you use this software in a product, an acknowledgment
  in the product documentation would be deeply appreciated but is not required.

  In the case of the GOLD Parser Engine source code, permission is granted
  to anyone to alter it and redistribute it freely, subject to the following
  restrictions:

  - The origin of this software must not be misrepresented; you must not claim
    that you wrote the original software.
  - Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.
  - This notice may not be removed or altered from any source distribution

  Copyright © 2015 Theodore Tsirpanis
  Copyright © 2018 Aleg "Kryvich" Azarouski
}
unit Scope;

interface

uses
  Classes, SysUtils, Generics.Collections, Variable;

const
  GLOBAL = 'GLOBAL';

type
  TMap = TDictionary<string, TVariable>;

  { TScope }

  TScope = class
  private
    FName: string;
    FParent: TScope;
    FVariables: TMap;
  public
    constructor Creeate(const sn: string = GLOBAL; const ps: TScope = nil);
    destructor Destroy; override;
    property Name: string read FName;
    property Parent: TScope read FParent;
    property Variables: TMap read FVariables;
  end;

implementation

{ TScope }

constructor TScope.Creeate(const sn: string; const ps: TScope);
begin
  FName := sn;
  FParent := ps;
  FVariables := TMap.Create;
end;

destructor TScope.Destroy;
begin
  FVariables.Free;
  inherited Destroy;
end;

end.
