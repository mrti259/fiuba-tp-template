{ pkgs, lib, config, inputs, ... }:

{
  languages.typst.enable = true;
  scripts.compile.exec = "typst compile --root . template/main.typ salida.pdf";
}
