program TekPort;

uses
  Forms,
  UfmTekClient in 'UfmTekClient.pas' {fmTekClient},
  UTekRPC in 'UTekRPC.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfmTekClient, fmTekClient);
  Application.Run;
end.
