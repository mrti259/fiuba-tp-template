# Publicar `sacayan-fiuba` en Typst Universe

Guía paso a paso para enviar el paquete al registro oficial
([typst/packages](https://github.com/typst/packages)). Una vez aceptado,
se usa con `#import "@preview/sacayan-fiuba:0.1.0"` y
`typst init @preview/sacayan-fiuba:0.1.0`.

## Requisitos previos

- Cuenta de GitHub.
- `gh` autenticado (o hacer fork + PR desde la web).
- Repo en estado verde: `compile` genera `out/main.pdf` con fecha de hoy y
  `typst init @preview/sacayan-fiuba:0.1.0` compila limpio.

## Checklist pre-PR (ya cumplido en este repo)

- [x] `typst.toml` completo: nombre, versión, entrypoint, authors, licencia,
      descripción, repository, keywords, `categories = ["report"]`, compiler.
- [x] `template/main.typ` importa el paquete por nombre (`@preview/...`),
      sin imports relativos. Compila out-of-the-box.
- [x] `thumbnail.png` en la raíz, 2067×2923, 227 KB
      (spec: lado largo ≥ 1080 px, ≤ 3 MiB).
- [x] `README.md` con ejemplos que compilan + sección de licencias
      (MIT código, MIT-0 ejemplo, licencias propias de los logos).
- [x] `LICENSE` con ambos textos (MIT y MIT-0).
- [x] Tamaño total ~340 KB (sin archivos grandes).
- [x] `exclude` deja fuera del bundle: devenv, `.devenv/`, `out/`, `docs/`.

## Paso a paso

1. **Fork** de [typst/packages](https://github.com/typst/packages)
   (botón Fork en GitHub).

2. **Clon liviano** (sparse checkout, como recomienda la doc oficial):

   ```sh
   git clone --filter=blob:none --sparse https://github.com/mrti259/packages.git
   cd packages
   git sparse-checkout set packages/preview
   ```

3. **Copiar el bundle** a `packages/preview/sacayan-fiuba/0.1.0/`.
   Solo estos 7 elementos (nada de devenv, `.gitignore` ni `out/`):

   ```
   typst.toml
   lib.typ
   assets/
   template/main.typ
   thumbnail.png
   README.md
   LICENSE
   ```

4. **Commit + push** a tu fork y **abrir el PR** contra
   `typst/packages:main`. Título sugerido:
   `Add sacayan-fiuba 0.1.0`.

5. **CI + review**: el CI valida el manifest, compila el template y revisa
   el thumbnail. Los mantenedores revisan nombre, licencias y calidad.
   Si piden cambios, se hacen sobre el mismo PR.

6. **Merge**: tras el merge y el CI verde, el paquete aparece en
   [Universe](https://typst.app/universe/) en ~30 minutos.

## Después de publicar

- La versión `0.1.0` queda **inmutable**: no se puede cambiar ni borrar.
  Errores o mejoras van en `0.1.1`, `0.2.0`, etc.
- Las actualizaciones las debe enviar el mismo autor de la versión anterior
  (si no, le preguntan antes de aprobar).
- En cada release nuevo, actualizar los números de versión en los imports
  del `README.md` y de `template/main.typ`.
- Referencia oficial del proceso:
  [docs/README.md](https://github.com/typst/packages/blob/main/docs/README.md)
  y [docs/manifest.md](https://github.com/typst/packages/blob/main/docs/manifest.md).
