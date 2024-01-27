unit UTekRPC;

interface
uses
  Windows, SysUtils, Classes, blcksock;

const
  HeadVersion = $80;
  EOL=$a;
  TekProgram = $af070600;    // TDS & DPO
  SendProcCode = $d0070000;  // TDS & DPO
  Inst0ProcCode = $3403a8c0; // TDS & DPO
  UScopeCode: DWORD = $afde;

type
  ERpcError = class(Exception)
  end;
  EZerroData = class(ERpcError)
  end;

  TAckType = (ConnectPort, SendData);
  // Followed to sunrpc in RPC.txt file
  TMessageType = (mtCALL, mtREPLY);
  TReplayState = (MSG_ACCEPTED, MSG_DENIED);
  TAcceptState = (asSUCCESS, // RPC executed successfully
                  PROG_ANAVAIL, // remote hasn't exported program
                  PROG_MISMATCH, // remote can't support version
                  PROC_UNAVAIL, // program can't support procedure
                  GARBAGE_ARGS, // procedure can't decode params
                  SYSTEM_ERR); // errors like memory allocation failure
  TRejectState = (RPC_MISMATCH, // RPC version number != 2
                  AUTH_ERROR);  // remote can't authenticate caller
  TAuthState = ( AUTH_OK, // success
             // failed at remote end
                 AUTH_BADCRED, // bad credential (seal broken)
                 AUTH_REJECTEDCRED, // client must begin new session
                 AUTH_BADVERF, // bad verifier (seal broken)
                 AUTH_REJECTEDVERF, // verifier expired or replayed
                 AUTH_TOOWEAK, // rejected for security reasons
             // failed locally
                 AUTH_INVALIDRESP, // bogus response verifier
                 AUTH_FAILED); // reason unknown

  TAuthType =(AUTH_NULL);
  TAuthRec = packed record
    Flavor: DWORD;
    Length: DWORD;
  end;

  TFragmentHeader = packed record
    HeaderVersion: Word;
    DataLength: Word;
  end;

  { TGetInst0Data }
  TGetInst0Data = packed record
    XID: DWORD;
    MessageType: DWORD;   // swap4(1)
    ReplyState: DWORD;  // 0
    Reserved: array[0..3] of DWORD;   // 0
    ScopeCode:  DWORD; // $afde TDS $beba DPO
    Quest2:  DWORD; //  $ed030000 TDS $d5020000 DPO
    Quest3: DWORD; // $100000
  end;

  { TReplyQueryData }
  TReplyQueryData = packed record
    XID: DWORD;
    MessageType: DWORD;  // 0
    ReplyState: DWORD;  // 0- accepted 1= executed
    Reserved: array[0..3] of DWORD;   // $af070600
    Quest5: DWORD;
    DataL:  DWORD;
  end;
  { TReplyQuery }
  TReplyQuery = class
  private
    Data: TReplyQueryData;
    fAnswer: string;
    function GetLAnswer: integer;
  public
    constructor Create;
    procedure Get(TCP: TTCPBlockSocket);

    property Answer: string read fAnswer;
    property LAnswer: integer read GetLAnswer;
  end;

  { TReplyInvalidData }
  TReplyInvalidData = packed record
    XID: DWORD;
    MessageType: DWORD;  // 0
    ReplyState: DWORD;  // 0- accepted 1= executed
    Reserved: array[0..2] of DWORD;
    ErrorCode: DWORD;  // swap4($f)
    Reserved1: array[0..1] of DWORD;
  end;
  { TReplyInvalid }
  TReplyInvalid = class
  private
    Data: TReplyInvalidData;
  public
    constructor Create;
    procedure Get(TCP: TTCPBlockSocket);
  end;


  { TReplySendData }
  TReplySendData = packed record  // 32 байта
    XID: DWORD;
    MessageType: DWORD;
    ReplayState: DWORD; // 0: Accepted 1:Executed
    Reserved: array[0..3] of DWORD;
    DataL: DWORD;
  end;

  { TSendInst0Data }
  TSendInst0Data = packed record
    XID: DWORD;
    MessageType: DWORD;   // 0
    RPC_Version: DWORD;  // $02000000
    RpcProgram: DWORD;   // $af070600 Tek protocol
    ProgramVersion: DWORD; // swap4(2)
    RpcProcedure: DWORD;  // swap4($b)
    Credentials: TAuthRec;
    Verifier: TAuthRec;
    ProcCode:  DWORD;  // $3403a8c0
    ProcVersion:  DWORD; //  0
    Protocol: DWORD; // swap4(8) or 0
    DataL:  DWORD;
  end;

  { TSendQueryData }
  TSendQueryData = packed record // Size=$40
    XID: DWORD;
    MessageType: DWORD;  // 0
    RPC_Version: DWORD;  // swap4(2)
    RpcProgram: DWORD;   // $af070600
    RpcVersion: DWORD; // swap4(1)
    RpcProcedure: DWORD;  // swap4($c)
    Credentials: TAuthRec;
    Verifier: TAuthRec;
    ScopeCode:  DWORD;  //  $afde Tek $babe DPO
    Quest4: DWORD; // $10270000 Tek $a0860100 DPO
    ProcCode:  DWORD; // $d0070000 Tek & DPO
    ProcVersion: DWORD; // 0
    Protocol: DWORD; // swap4($80) Tek 0 DPO
    DataCode:  DWORD;  // swap4($a)
  end;

  { TSunrpcGetPortData }
  TSunrpcGetPortData = packed record // Size=28=$1c
    XID: DWORD;
    MessageType: DWORD;
    ReplayState: DWORD; // 0: Accepted 1:Executed
    Reserved: array[0..2] of DWORD;
    PortNumber: DWORD;
  end;

  { TSunrpcQueryPortData }
  TSunrpcQueryPortData = packed record // Size=$38
    XID: DWORD;
    MessageType: DWORD; // 0
    RPC_Version: DWORD;  // swap4(2)
    RpcProgram: DWORD;   // $a0860100(100000)Portmap
    ProgramVersion: DWORD; // swap4(2)
    RpcProcedure: DWORD;  // swap4(3) GetPort
    Credentials: TAuthRec;
    Verifier: TAuthRec;
    ProcCode:  DWORD;  //  $af070600
    ProcVersion:  DWORD; // swap4(1)
    Protocol: DWORD; // swap4(6)
    Port: DWORD;    // $0
  end;

  { TTekrpcWriteData }
  TTekrpcWriteData = packed record  // Size=$3c
    XID: DWORD;
    MessageType: DWORD;   // 0
    RPC_Version: DWORD;  // $02000000
    RpcProgram: DWORD;   // $af070600 Tek protocol
    ProgramVersion: DWORD; // swap4(2)
    RpcProcedure: DWORD;  // swap4($b)
    Credentials: TAuthRec;
    Verifier: TAuthRec;
    ScopeCode: DWORD; //  $afde
    ProcCode:  DWORD;  // $d0070000
    ProcVersion:  DWORD; //  0
    Protocol: DWORD; // swap4(8) or 0
    DataL:  DWORD;
  end;

  TGetInst0 = class(TObject)
  private
    Data: TGetInst0Data;
  public
    constructor Create;
    procedure Get( TCP: TTCPBlockSocket);
  end;

  TReplySend = class
  private
    Data: TReplySendData;
  public
    constructor Create;
    procedure Get( TCP: TTCPBlockSocket);
  end;

  TSendInst0 = class(TObject)
  private
    Data: TSendInst0Data;
  public
    constructor Create;
    procedure Put( TCP: TTCPBlockSocket);
  end;

  TSendQuery = class
  private
    Data: TSendQueryData;
  public
    constructor Create( aQuest4, aProtocol: DWORD);
    procedure Put( TCP: TTCPBlockSocket);
  end;

  TSunrpcGetPort = class(TPersistent)
  private
    Data: TSunrpcGetPortData;
    fPort: integer;
  public
    constructor Create;
    procedure Get(TCP: TTCPBlockSocket);

    property Port: integer read fPort;
  end;

  TSunrpcQueryPort = class(TPersistent)
  private
    Data: TSunrpcQueryPortData;
  public
    constructor Create;
    procedure Put( TCP: TTCPBlockSocket);
  end;

  TTekrpcWrite = class
  private
    Data: TTekrpcWriteData;
    cmd: string;
  public
    constructor Create;
    procedure Put( TCP: TTCPBlockSocket; command: string);

    property Command: string read cmd;
  end;


implementation
var
  LastXID: DWORD;
  XStream: TMemoryStream;
  MainHeader: TFragmentHeader;
  LastCommandLength: integer;

function swap2(x: word): WORD;
var
  R: word;
begin
  R := Lo(x);
  R := (R shl 8) or Hi(x);
  result := R;
end;

function swap4(x: DWORD): DWORD;
var
  Rarr: array[0..3] of byte;
  R: DWORD;
begin
  move(X,Rarr,4);
  R := Rarr[0];
  R := (R shl 8) or Rarr[1];
  R := (R shl 8) or Rarr[2];
  R := (R shl 8) or Rarr[3];
  result := R;
end;

function CreateXID: DWORD;
begin
  LastXID := random($ffff);
  LastXID := swap4(LastXID);
  result := LastXID;
end;

  { TGetInst0 }

constructor TGetInst0.Create;
begin
  inherited;
end;

procedure TGetInst0.Get(TCP: TTCPBlockSocket);
begin
  XStream.Clear;
  TCP.RecvStreamRaw(XStream, 1000);
  XStream.Seek(0, soFromBeginning);
  XStream.Read(MainHeader, SizeOf(MainHeader));
  if MainHeader.HeaderVersion<>HeadVersion then
    raise ERpcError.Create('Invalid Header');
  XStream.Read(Data, SizeOf(Data));
  XStream.Clear;
  Data.MessageType := swap4(Data.MessageType);
  Data.ReplyState := swap4(Data.ReplyState);
  UScopeCode := Data.ScopeCode;
  if Data.XID<>LastXID then
    raise ERpcError.Create('Invalid XID');
  if Data.MessageType<>1 then
    raise ERpcError.Create('Invalid message type');
  if Data.ReplyState<>0 then
    raise ERpcError.Create('RPC call not accepted');
end;

constructor TReplyQuery.Create;
begin
  inherited;
end;

  { TReplyQuery }

procedure TReplyQuery.Get(TCP: TTCPBlockSocket);
var
  Str: string;
begin
  XStream.Clear;
  TCP.RecvStreamRaw(XStream, 1000);
  if XStream.Size=0 then
    raise EZerroData.Create('Receive 0 byte data');
  XStream.Seek(0, soFromBeginning);
  XStream.Read(MainHeader, SizeOf(MainHeader));
  if MainHeader.HeaderVersion<>HeadVersion then
    raise ERpcError.Create('Invalid Header');
  XStream.Read(Data, SizeOf(Data));
  Data.MessageType := swap4(Data.MessageType);
  Data.ReplyState := swap4(Data.ReplyState);
  Data.DataL := swap4(Data.DataL);
  if Data.XID<>LastXID then
    raise ERpcError.Create('Invalid XID');
  if Data.MessageType<>1 then
    raise ERpcError.Create('Invalid message type');
  if Data.ReplyState<>0 then
    raise ERpcError.Create('RPC call not accepted');
  if Data.DataL>0 then
  begin
    SetLength(Str,Data.DataL);
    XStream.Read(Str[1],Data.DataL);
    fAnswer := Str;
  end;
end;

function TReplyQuery.GetLAnswer: integer;
begin
  result := Data.DataL;
end;

{ TReplyInvalid }

constructor TReplyInvalid.Create;
begin
  inherited;
end;

procedure TReplyInvalid.Get(TCP: TTCPBlockSocket);
begin
  XStream.Clear;
  TCP.RecvStreamRaw(XStream, 1000);
  if XStream.Size=0 then
    raise EZerroData.Create('Receive 0 byte data');
  XStream.Seek(0, soFromBeginning);
  XStream.Read(MainHeader, SizeOf(MainHeader));
  if MainHeader.HeaderVersion<>HeadVersion then
    raise ERpcError.Create('Invalid Header');
  XStream.Read(Data, SizeOf(Data));
  Data.MessageType := swap4(Data.MessageType);
  Data.ReplyState := swap4(Data.ReplyState);
  Data.ErrorCode := swap4(Data.ErrorCode);
  if Data.XID<>LastXID then
    raise ERpcError.Create('Invalid XID');
  if Data.MessageType<>1 then
    raise ERpcError.Create('Invalid message type');
  if Data.ReplyState<>0 then
    raise ERpcError.Create('RPC call not accepted');
  if Data.ErrorCode = $f then
    raise ERpcError.Create('No data for reply');
end;

  { TReplySend }

constructor TReplySend.Create;
begin
  inherited;
end;

procedure TReplySend.Get(TCP: TTCPBlockSocket);
begin
  XStream.Clear;
  TCP.RecvStreamRaw(XStream, 1000);
  XStream.Seek(0, soFromBeginning);
  XStream.Read(MainHeader, SizeOf(MainHeader));
  if MainHeader.HeaderVersion<>HeadVersion then
    raise ERpcError.Create('Invalid Header');
  XStream.Read(Data, SizeOf(Data));
  Data.MessageType := swap4(Data.MessageType);
  Data.DataL := swap4(Data.DataL);
  if Data.XID<>LastXID then
    raise ERpcError.Create('Invalid XID');
  if Data.MessageType<>1 then
    raise ERpcError.Create('Invalid message type');
  if Data.ReplayState<>0 then
    raise ERpcError.Create('RPC call not accepted');
  if Data.DataL<>LastCommandLength then
    raise ERpcError.Create('Invalid command length');
end;

  { TSendInst0 }

constructor TSendInst0.Create;
begin
  inherited;
  with Data do
  begin
    XID := 0;
    MessageType := 0;
    RPC_Version :=swap4(2);
    RpcProgram := TekProgram;
    ProgramVersion := swap4(1);
    RpcProcedure := swap4($a);
    Credentials.Flavor := 0;
    Verifier.Flavor := 0;
    Credentials.Length := 0;
    Verifier.Length := 0;
    ProcCode := Inst0ProcCode;
    ProcVersion := 0;
    Protocol := 0;
    DataL := swap4(5);
  end;
end;

procedure TSendInst0.Put(TCP: TTCPBlockSocket);
const
  inst0: array[1..8] of char = ('i','n','s','t','0',#0,#0,#0);
begin
  XStream.Clear;
  MainHeader.HeaderVersion := HeadVersion;
  MainHeader.DataLength := swap2($40);
  XStream.Write(MainHeader, SizeOf(MainHeader));
  Data.XID := CreateXID;
  XStream.Write(Data,SizeOf(Data));
  XStream.Write(inst0, 8);
  XStream.Seek(0, soFromBeginning);
  TCP.SendStreamRaw(XStream);
  XStream.Clear;
end;

  { TSendQuery }

constructor TSendQuery.Create(aQuest4, aProtocol: DWORD);
begin
 with Data do
 begin
   XID := CreateXID;
   MessageType := 0;
   RPC_Version := swap4(2);
   RpcProgram := TekProgram;
   RpcVersion := swap4(1);
   RpcProcedure := swap4($c);
   Credentials.Flavor := 0;
   Credentials.Length := 0;
   Verifier.Flavor := 0;
   Verifier.Length := 0;
   ScopeCode :=  UScopeCode;
   Quest4 := aQuest4;
   ProcCode := SendProcCode;
   ProcVersion :=0;
   Protocol := aProtocol;
   DataCode := swap4($a)
 end;
end;

procedure TSendQuery.Put(TCP: TTCPBlockSocket);
begin
  Data.XID := CreateXID;
  XStream.Clear;
  MainHeader.HeaderVersion := HeadVersion;
  MainHeader.DataLength := swap2(SizeOf(Data));
  XStream.Write(MainHeader, SizeOf(MainHeader));
  XStream.Write(Data,SizeOf(Data));
  XStream.Seek(0, soFromBeginning);
  TCP.SendStreamRaw(XStream);
end;

  { TSunrpcGetPort }

constructor TSunrpcGetPort.Create;
begin
  inherited;
end;

procedure TSunrpcGetPort.Get(TCP: TTCPBlockSocket);
begin
  XStream.Clear;
  TCP.RecvStreamRaw(XStream, 1000);
  XStream.Seek(0, soFromBeginning);
  XStream.Read(MainHeader, SizeOf(MainHeader));
  if MainHeader.HeaderVersion<>HeadVersion then
    raise ERpcError.Create('Invalid Header');
  XStream.Read(Data, SizeOf(Data));
  if Data.XID<>LastXID then
    raise ERpcError.Create('Invalid XID');
  if Data.ReplayState<>0 then
    raise ERpcError.Create('Invalid reply in GetPort');
  fPort := swap4(Data.PortNumber);
end;

  { TSunrpcQueryPort }

  constructor TSunrpcQueryPort.Create;
begin
  inherited;
  with Data do
  begin
    XID :=0;
    MessageType := 0;
    RPC_Version := swap4(2);
    RpcProgram := $a0860100; //(100000)Portmap
    ProgramVersion := swap4(2);
    RpcProcedure := swap4(3); // GetPort
    Credentials.Flavor := 0;
    Verifier.Flavor := 0;
    Credentials.Length := 0;
    Verifier.Length := 0;
    ProcCode :=  $af070600;
    ProcVersion := swap4(1);
    Protocol := swap4(6);
    Port := $0;
  end;
end;

procedure TSunrpcQueryPort.Put(TCP: TTCPBlockSocket);
begin
  Data.XID := CreateXID;
  MainHeader.HeaderVersion := HeadVersion;
  MainHeader.DataLength := swap2(SizeOf(Data));
  XStream.Clear;
  XStream.Write(MainHeader, SizeOf(MainHeader));
  XStream.Write(Data,SizeOf(Data));
  XStream.Seek(0,soFromBeginning);
  TCP.SendStreamRaw(XStream);
  //TCP.WaitingData;
  XStream.Clear;
end;

  { TTekrpcWrite }
constructor TTekrpcWrite.Create;
begin
  inherited;
  with Data do
  begin
    XID := 0;
    MessageType := 0;
    RPC_Version := swap4(2);
    RpcProgram := TekProgram; // Tek protocol
    ProgramVersion := swap4(1);
    RpcProcedure := swap4($b);
    Credentials.Flavor := 0;
    Credentials.Length := 0;
    Verifier.Flavor := 0;
    Verifier.Length := 0;
    ScopeCode := UScopeCode;
    ProcCode := SendProcCode;
    ProcVersion := 0;
    Protocol := 0; // swap4(8) or 0
    DataL := 0;
  end;
end;

procedure TTekrpcWrite.Put(TCP: TTCPBlockSocket; command: string);
var
  DL: integer;
  dummy: array[1..3] of byte;
begin
  cmd := command;
  Data.XID := CreateXID;
  Data.DataL := swap4(length(cmd));
  LastCommandLength := length(cmd);
  XStream.Clear;
  MainHeader.HeaderVersion := HeadVersion;
  DL := SizeOf(Data)+length(cmd);
  // DataLength must be
  if (DL mod 4)=0 then
    MainHeader.DataLength := swap2(DL)
  else
    MainHeader.DataLength := swap2(((DL div 4)+1)*4);
  XStream.Write(MainHeader, SizeOf(MainHeader));
  XStream.Write(Data,SizeOf(Data));
  XStream.Write(cmd[1], length(cmd));
  if not ((DL mod 4)=0) then
    XStream.Write(dummy,4-(DL mod 4));
  XStream.Seek(0, soFromBeginning);
  TCP.SendStreamRaw(XStream);
  XStream.Clear;
end;


initialization
  XStream := TMemoryStream.Create;

finalization
  XStream.Free;

end.
