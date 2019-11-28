program DIfont;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, tachartlazaruspkg, main, creator
  { you can add units after this };

{$R *.res}

begin
  Application.Title:='DIYen Font Editor';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TFM, FM);
  Application.CreateForm(TFCreator, FCreator);
  Application.Run;
end.

