# Plantilla FIUBA para Typst

Carátula + estilos base para documentos académicos de la Facultad de Ingeniería (UBA).

## Uso

```typst
#import "../lib.typ": fiuba-tp

#show: fiuba-tp.with(
  titulo: "Título del trabajo",
  subtitulo: "Opcional",
  materia-codigo: "XX.XX",
  materia-nombre: "Nombre de la materia",
  catedra: "Cátedra Apellido",
  docente: "Prof. Nombre Apellido", // opcional
  cuatrimestre: "N.º cuatrimestre",
  anio: "2026",
  autores: (
    (nombre: "Apellido, Nombre", padron: "000000", email: "nombre@fi.uba.ar"),
  ),
)
```

Ver ejemplo completo en `template/main.typ`.

## Compilar

```sh
typst compile --root . template/main.typ salida.pdf
```

Con devenv: `languages.typst.enable = true` ya está en `devenv.nix` (provee `typst` + `tinymist`).

## Logos

`assets/uba.svg` (escudo UBA, dominio público) y `assets/fiuba.png` (logo FIUBA, CC-BY-2.5 vía Wikimedia Commons). Reemplazables con los parámetros `logo-uba` / `logo-fiuba`.
