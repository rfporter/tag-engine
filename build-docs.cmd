@echo off
rem Builds the Antidoc project docs and the user manual with the Ruby that AsciiDoc for LabVIEW
rem installs. Arguments are passed on to build-docs.rb (try --help).
setlocal
set "RUBY=%LOCALAPPDATA%\Asciidoc For LabVIEW\RubyInstance\bin\ruby.exe"
if not exist "%RUBY%" (
  echo Ruby from AsciiDoc for LabVIEW not found: %RUBY%
  exit /b 1
)
"%RUBY%" "%~dp0build-docs.rb" %*
