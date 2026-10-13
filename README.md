# sacayan-fiuba

Plantilla Typst para documentos académicos de la Facultad de Ingeniería (UBA): carátula con autores, curso y logos UBA+FIUBA.

## Uso

```typst
#import "@preview/sacayan-fiuba:0.1.0": fiuba-tp

#show: fiuba-tp.with(
  titulo: "Título del trabajo",
  subtitulo: "Subtítulo opcional",
  materia-codigo: "XX.XX",
  materia-nombre: "Nombre de la materia",
  catedra: "Cátedra Apellido",
  docente: "Prof. Nombre Apellido",
  cuatrimestre: "N.º cuatrimestre",
  anio: "2026",
  autores: (
    (nombre: "Apellido, Nombre", padron: "000000", email: "nombre@fi.uba.ar"),
  ),
)
```

Ver ejemplo completo en `template/main.typ`.

## Parámetros

| Parámetro | Obligatorio | Default | Descripción |
|---|---|---|---|
| `titulo` | sí | — | Título del trabajo (carátula) |
| `materia-nombre` | sí | — | Nombre de la materia |
| `autores` | sí | — | Lista de `(nombre, padron, email)` |
| `subtitulo` | no | — | Subtítulo bajo el título |
| `titulo-corto` | no | `titulo` | Texto del header en páginas 2+ |
| `materia-codigo` | no | — | Código (ej. `XX.XX`); si se omite, el header muestra solo el nombre |
| `catedra` | no | — | Cátedra |
| `docente` | no | — | Docente |
| `cuatrimestre` | no | — | Cuatrimestre |
| `anio` | no | — | Año |
| `fecha` | no | `auto` (= hoy) | Fecha de la carátula. Acepta texto (`"10/03/2026"`) o `none` (oculta la línea) |
| `logo-uba` | no | `assets/uba.svg` | Ruta al escudo UBA |
| `logo-fiuba` | no | `assets/fiuba.png` | Ruta al logo FIUBA |

## Compilar

Para crear un proyecto nuevo desde el template:

```sh
typst init @preview/sacayan-fiuba:0.1.0 miproyecto
cd miproyecto
typst compile main.typ salida.pdf   # o: typst watch main.typ
```

## Desarrollo (solo en este repo)

```sh
devenv shell
link               # registra el paquete localmente
compile            # link + compila template/main.typ a out/main.pdf
compile otro.pdf   # salida con otro nombre
unlink             # elimina el registro local del paquete
```

### Nota sobre la fecha

Typst respeta la variable `SOURCE_DATE_EPOCH`. Los shells de Nix/devenv la exportan fijada en `1980-01-01` (builds reproducibles), por lo que `fecha: auto` mostraría `01/01/1980` al compilar directo con `typst compile` dentro de `devenv shell`. El script `compile` la desactiva automáticamente. Para un PDF reproducible con fecha fija, pasá `fecha: "dd/mm/aaaa"` explícita.

## Logos

La licencia MIT del paquete cubre los archivos `.typ`. Los logos tienen licencias propias:

- `assets/uba.svg`: escudo de la UBA, dominio público.
- `assets/fiuba.png`: logo de FIUBA, [CC-BY-2.5](https://creativecommons.org/licenses/by/2.5/) vía [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Uba_fiuba_ingenieria_logo.png) (autor desconocido). Requiere atribución si lo redistribuís fuera de este paquete.

Reemplazables con los parámetros `logo-uba` / `logo-fiuba`.

## Licencia

- Código (`.typ` fuera de `template/`): MIT.
- Ejemplo (`template/`): MIT-0 — usalo en tu TP sin citar nada.
- Logos: ver sección Logos.
