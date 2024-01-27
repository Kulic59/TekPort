unit UfmTekClient;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ScktComp, Buttons, StdCtrls, Psock, AppEvnts, Grids, blcksock, UTekRPC;

type
  TfmTekClient = class(TForm)
    bnConnect: TButton;
    bnSend: TButton;
    bnClose: TBitBtn;
    edPort: TEdit;
    Label1: TLabel;
    edServer: TEdit;
    ApplicationEvents1: TApplicationEvents;
    bnRead: TButton;
    memLog: TMemo;
    bnClear: TBitBtn;
    ecbCommand: TComboBox;
    bnGetPort: TButton;
    procedure FormDestroy(Sender: TObject);
    procedure bnConnectClick(Sender: TObject);
    procedure bnSendClick(Sender: TObject);
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure ClientSocketStatus(Sender: TComponent; const sOut: String);
    procedure bnReadClick(Sender: TObject);
    procedure bnClearClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bnGetPortClick(Sender: TObject);
  private
    { Private declarations }
    fClientSocket: TTCPBlockSocket;
    fConnected: boolean;
    fTimeOut: Integer;
    fHostCode: DWORD;
    fScopeCode: DWORD;
    fRecCode: Word;
    procedure SetConnected(AValue: boolean);
    procedure ClientSocketConnected(Sender: TObject);
  public
    { Public declarations }
    procedure Log(str: string);
    procedure SendAck;
    procedure GetAnswer;
    property ClientSocket: TTCPBlockSocket read fClientSocket write fClientSocket;
    property Connected: boolean read fConnected write SetConnected;
    property TimeOut: Integer read fTimeOut;
    property HostCode: DWORD read fHostCode;
    property ScopeCode: DWORD read fScopeCode;
  end;

var
  fmTekClient: TfmTekClient;

implementation

{$R *.DFM}

procedure TfmTekClient.FormCreate(Sender: TObject);
begin
  inherited;
  FTimeOut := 1000;
  fHostCode := $0000afde;
  fScopeCode := $d0070000;
  fClientSocket := TTCPBlockSocket.Create;
  ClientSocket.OnAfterConnect := ClientSocketConnected;
  Randomize;
end;

procedure TfmTekClient.FormDestroy(Sender: TObject);
begin
  Connected := false;
  ClientSocket.free;
  inherited;
end;

procedure TfmTekClient.bnConnectClick(Sender: TObject);
begin
  Connected := true;
end;

procedure TfmTekClient.bnSendClick(Sender: TObject);
var
  Send: TTekrpcWrite;
  Reply: TReplySend;
begin
  Send := TTekrpcWrite.Create;
  try
    Send.Put(ClientSocket, ecbCommand.Text+#10);
  finally
    Send.Free;
  end;
  Reply := TReplySend.Create;
  try
    Reply.Get(ClientSocket);
  finally
    Reply.Free;
  end;
  memLog.Lines.Add( 'sended:'+ecbCommand.Text);
end;

procedure TfmTekClient.ApplicationEvents1Exception(Sender: TObject;
  E: Exception);
begin
  //Application.ShowException( E);
end;

procedure TfmTekClient.ClientSocketStatus(Sender: TComponent;
  const sOut: String);
begin
  memLog.Lines.Add( 'Status:'+sOut);
end;

procedure TfmTekClient.bnReadClick(Sender: TObject);
var
  SendQuery: TSendQuery;
  ReplyQuery: TReplyQuery;
  ReplyInvalid: TReplyInvalid;
begin
  SendQuery := TSendQuery.Create($10270000,$80000000);
  try
    SendQuery.Put(ClientSocket);
  finally
    SendQuery.Free;
  end;
  ReplyQuery := TReplyQuery.Create;
  ReplyInvalid := TReplyInvalid.Create;
  try
    try
      ReplyQuery.Get(ClientSocket);
    except
      On EZerroData do
        ReplyInvalid.Get(ClientSocket);
    end;
    memLog.Lines.Add('GetS='+ReplyQuery.Answer);
  finally
    ReplyQuery.Free;
    ReplyInvalid.Free;
  end;
end;

procedure TfmTekClient.bnClearClick(Sender: TObject);
begin
  memLog.Clear;
end;

procedure TfmTekClient.SetConnected(AValue: boolean);
var
  SendInst0: TSendInst0;
  GetInst0: TGetInst0;
begin
  if fConnected=AValue then Exit;
  if AValue then
  begin
    ClientSocket.Connect(edServer.Text,edPort.Text);
    if not Connected then exit;
    SendInst0 := TSendInst0.Create;
    try
      SendInst0.Put(ClientSocket);
    finally
      SendInst0.Free;
    end;
    GetInst0 := TGetInst0.Create;
    try
      GetInst0.Get(ClientSocket);
    finally
      GetInst0.Free;
    end;
  end
  else
  begin
    ClientSocket.CloseSocket;
    fConnected := false;
  end;
end;

procedure TfmTekClient.ClientSocketConnected(Sender: TObject);
begin
  fConnected := true;
  //SendCommand('inst0',0,$a);
  Log('Connected successfully');
  {$IFDEF debuginterface}
  DebugLN('XStream Socket connected successfully');
  {$ENDIF}
end;

procedure TfmTekClient.SendAck;
begin
  // TODO -cMM: TfmTekClient.SendAck default body inserted
end;

procedure TfmTekClient.GetAnswer;
begin
  // TODO -cMM: TfmTekClient.GetAnswer default body inserted
end;


procedure TfmTekClient.Log(str: string);
begin
  memLog.Lines.Add(str);
end;

{ TReplyQuery }

{ TReplySend }

{ TSendQuery }

{ TSunrpcGetPort }

{ TSunrpcQueryPort }

{ TTekrpcWrite }

procedure TfmTekClient.bnGetPortClick(Sender: TObject);
var
  QueryPort: TSunrpcQueryPort;
  GetPort: TSunrpcGetPort;
begin
  QueryPort := TSunrpcQueryPort.Create;
  GetPort := TSunrpcGetPort.Create;
  try
    ClientSocket.Connect(edServer.Text,'111'); // connect to sunrpc
    try
      QueryPort.Put(ClientSocket);
      GetPort.Get(ClientSocket);
      Log('Get Port='+IntToStr(GetPort.Port));
      edPort.Text := IntToStr(GetPort.Port);
    finally
      ClientSocket.CloseSocket;
    end;
  finally
    FreeAndNil(QueryPort);
    FreeAndNil(GetPort);
  end;
  Connected := false;
end;

{ TWriteInst0 }

{ TGetInst0 }

end.
