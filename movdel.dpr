Program movdel;

Uses
  Forms,
  unit1 In 'unit1.pas' {MainForm};

{$R *.res}
{$SetPEFlags 1}

Begin
  Application.Initialize;
  Application.Title := 'movdel';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
End.
