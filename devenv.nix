{ pkgs, lib, config, inputs, ... }:

{
  languages.typst.enable = true;

  scripts = {
    link = {
      description = "Registra el paquete localmente como @preview/sacayan-fiuba:0.1.0";
      exec = ''
        dest="''${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages/preview/sacayan-fiuba/0.1.0"
        mkdir -p "$(dirname "$dest")"
        ln -sfn "$DEVENV_ROOT" "$dest"
        echo "linked $dest -> $DEVENV_ROOT"
      '';
    };

    unlink = {
      description = "Elimina el registro local de @preview/sacayan-fiuba";
      exec = ''
        target="''${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages/preview/sacayan-fiuba"
        rm -f "$target/0.1.0"
        rmdir -p "$target" 2>/dev/null || true
        echo "unlinked $target"
      '';
    };

    compile = {
      description = "Compila template/main.typ a out/main.pdf";
      exec = ''
        unset SOURCE_DATE_EPOCH
        link
        mkdir -p out
        typst compile --root . template/main.typ "''${1:-out/main.pdf}"
      '';
    };
  };
}
