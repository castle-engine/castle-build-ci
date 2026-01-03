{$mode objfpc}{$H+}
uses SysUtils;
begin
  WriteLn('PATH is ', GetEnvironmentVariable('PATH'));
  WriteLn('HOME is ', GetEnvironmentVariable('HOME'));
  WriteLn('CASTLE_ENGINE_PATH is ', GetEnvironmentVariable('CASTLE_ENGINE_PATH'));

  WriteLn('fpc is ',  FileSearch('fpc', GetEnvironmentVariable('PATH')));
  WriteLn('fpc.exe is ',  FileSearch('fpc.exe', GetEnvironmentVariable('PATH')));
end.