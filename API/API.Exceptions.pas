unit API.Exceptions;

interface

uses
  System.SysUtils;

type

  EAPIException = class(Exception)
  private
    FResponse: string;
    FCode: Integer;
    FTime: TDateTime;
    FErrorMsg: string;
    FRequest: string;
    FMethod: string;
  public
    constructor Create(AException: Exception); reintroduce; overload;
    constructor Create(const ACode: Integer; const AErrorMsg: string; AResponse: string = ''; ARequest: string = ''); reintroduce; overload;

    function ToString: string; override;

    property Code: Integer read FCode write FCode;
    property ErrorMsg: string read FErrorMsg write FErrorMsg;
    property Response: string read FResponse write FResponse;
    property Request: string read FRequest write FRequest;
    property Method: string read FMethod;
    property Time: TDateTime read FTime write FTime;
  end;

  TOnAPIError = procedure(ASender: TObject; const Exception: EAPIException) of object;
  TOnError = procedure(ASender: TObject; const AException: Exception) of object;

implementation

uses
  Net.Utils;

{ EAPIException }

constructor EAPIException.Create(AException: Exception);
begin
  Create(-1, AException.Message, EmptyStr);
end;

constructor EAPIException.Create(const ACode: Integer; const AErrorMsg: string;
  AResponse, ARequest: string);
var
  Prot, User, Pass, Host, Port, Path, Para: string;
begin
  FCode := ACode;
  FErrorMsg := AErrorMsg;
  FResponse := AResponse;
  FRequest := ARequest;
  FTime := Now;

  ParseURL(ARequest, Prot, User, Pass, Host, Port, Path, Para);
  FMethod := Path;

  inherited CreateFmt('%d: %s', [FCode, ErrorMsg]);
end;

function EAPIException.ToString: string;
begin
  Result := Format('(%d): %s', [FCode, FErrorMsg]);
end;

end.
