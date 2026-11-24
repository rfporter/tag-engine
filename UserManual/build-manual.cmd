@echo off
rem Builds the Tag Engine user manual with the Ruby that AsciiDoc for LabVIEW installs.
rem Arguments are passed on to build-manual.rb (try --help).
setlocal
set "RUBY=%LOCALAPPDATA%\Asciidoc For LabVIEW\RubyInstance\bin\ruby.exe"
if not exist "%RUBY%" (
  echo Ruby from AsciiDoc for LabVIEW not found: %RUBY%
  exit /b 1
)
"%RUBY%" "%~dp0build-manual.rb" %*
