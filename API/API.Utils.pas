unit API.Utils;

interface

uses System.Classes, System.SysUtils;

{ Конвертирует MemoryStream в string }
function MemStreamToStr(const MemStream: TMemoryStream; Encoding: TEncoding): string; overload;
function MemStreamToStr(const MemStream: TMemoryStream): string; overload;

implementation

function MemStreamToStr(const MemStream: TMemoryStream; Encoding: TEncoding): string;
var StringStream: TStringStream;
begin
  StringStream := TStringStream.Create('', TEncoding.UTF8);
  try
    MemStream.Position := 0;
    StringStream.CopyFrom(MemStream, MemStream.Size);
    Result := StringStream.DataString;
  finally
    FreeAndNil(StringStream);
  end;
end;

function MemStreamToStr(const MemStream: TMemoryStream): string; overload;
begin
  Result := MemStreamToStr(MemStream, TEncoding.UTF8);
end;

end.
