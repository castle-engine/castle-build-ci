# GitHub Actions and PATH= in GITHUB_ENV

This is an explanation for `prepend_to_path` im `setup_castle_engine`,
more spefically why it doesn't call `preserve_variable_for_future_ci_steps PATH`.

When inside GitHub Actions runner, never modify `PATH` environment variable through `GITHUB_ENV` entry like `PATH=...:$PATH`. Instead, always add to `GITHUB_PATH`.

Reason: The `PATH=` definition in `$GITHUB_ENV` would fail in a weird way on Windows runners using bash, making GHA confused whether PATH contains Unix paths (`:` as entry separator) or Windows paths (`;` as entry separator, `:` as drive letter separator).

This can be reproduced doing in GHA YAML these 2 steps:

```
- name: Break PATH for next steps
  run: echo "PATH=$PATH" >> $GITHUB_ENV

- name: Test is PATH broken in next step
  run: |
    echo ---------------------------------------
    echo PATH in a different step, as seen from bash:
    echo $PATH
    echo ---------------------------------------
    echo PATH in a different step, as seen from Windows native application:
    ./some_windows_native_app_that_prints_path.exe
```

The sample `some_windows_native_app_that_prints_path.exe` could be done by compiling program like this with FPC:

```delphi
{$mode objfpc}{$H+}
uses SysUtils;
begin
  WriteLn('PATH is ', GetEnvironmentVariable('PATH'));
  //WriteLn('HOME is ', GetEnvironmentVariable('HOME'));
  //WriteLn('CASTLE_ENGINE_PATH is ', GetEnvironmentVariable('CASTLE_ENGINE_PATH'));
  //WriteLn('Search fpc is ',  FileSearch('fpc', GetEnvironmentVariable('PATH')));
  //WriteLn('Search fpc.exe is ',  FileSearch('fpc.exe', GetEnvironmentVariable('PATH')));
end.
```

Note that `$PATH` within `$GITHUB_ENV` must contain Unix path as it's interpreted by bash and other Unix tools. In 2nd step above, `$PATH` in bash seems normal, but `$PATH` in native Windows application `some_windows_native_app_that_prints_path.exe` is broken: (newlines below added for readability only)

```
PATH is
C:\Program Files\Git\mingw64\bin;
C:\Program Files\Git\usr\bin;
C:\Users\runneradmin\bin;
/mingw64/bin:
/usr/bin:
/c/Users/runneradmin/bin:
/c/Program Files/MongoDB/Server/7.0/bin:
/c/vcpkg:
/c/tools/zstd:
...
```

So it actually contains both Unix and Windows paths, glues and confused. Latter part makes no sense for the Windows application, that expects `;` as entry separator, and thus fails to find anything in the Unix paths.

- Maybe GHA tries to combine internal paths from GITHUB_PATH with PATH?
- Maybe related to https://github.com/actions/toolkit/issues/655 ?
- See https://github.com/castle-engine/castle-build-ci/actions/runs/20686169133/job/59387117371

Solution is just to use `GITHUB_PATH` instead of `PATH=` in `GITHUB_ENV`.