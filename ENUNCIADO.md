# Wikipedia Article Analysis — TP Diseño

Sistemas Distribuidos I (75.74)

## Wikipedia

> "Wikipedia es una enciclopedia libre, políglota y editada de manera colaborativa. Es administrada por la Fundación Wikimedia, una organización sin ánimo de lucro cuya financiación está basada en donaciones. Sus más de 67 millones de artículos en 334 idiomas han sido redactados en conjunto por voluntarios de todo el mundo, lo que suma más de 3500 millones de ediciones, y permite que cualquier persona pueda sumarse al proyecto para editarlos, a menos que la página se encuentre protegida contra vandalismos para evitar problemas o disputas. Se trata de la obra de referencia más extensa y más leída de la historia." [1]
>
> [1] https://es.wikipedia.org/wiki/Wikipedia

## Requerimientos Funcionales

- Se solicita un sistema distribuido que analice un conjunto de artículos obtenidos de Wikipedia en los idiomas Francés e Inglés.
- Se debe obtener:
  1. Url y fecha de modificación para artículos escritos en inglés hasta 2020 inclusive.
  2. Nombre, url e imágen (bytes) de artículos escritos hasta 2020 inclusive que incluyan "biography" o "biographie" entre sus secciones.
  3. Listado de palabras únicas compartidas entre cualquier artículo escrito en inglés y cualquier artículo escrito en francés.
  4. Pares (palabra, cantidad) del top 20 palabras más utilizadas entre todos los abstracts. Dentro de un mismo abstract las palabras se cuentan una sola vez y las palabras triviales (stopwords) se excluyen del top.
  5. Url y cantidad de palabras de abstract para los artículos escritos a partir del 2021 cuya cantidad de palabras en el abstract sea superior al promedio de palabras de abstract de todos los artículos escritos hasta el 2020 inclusive. Se aplica el mismo criterio para contabilizar palabras que la query anterior.

## Requerimientos No Funcionales

- Se requiere poder atender consultas aisladas de múltiples clientes. No es necesario permitir más de una única ejecución por cliente.
- El sistema debe estar optimizado para entornos multicomputadoras. Se debe soportar el incremento de los elementos de cómputo para escalar respecto a la cantidad de clientes atendidos y al volúmen de información a procesar por cliente.
- Se requiere del desarrollo de un Middleware para abstraer la comunicación basada en grupos.
- Se debe garantizar graceful quit frente a señales SIGTERM.

## Datasets, notebook patrón y librerías

- Se trabajará sobre los datos de un dataset de Kaggle.
- Para la descarga de las imágenes se recomienda el uso de la API de Wikimedia.
- Se provee un notebook de referencia para guiar la interpretación del enunciado. No obstante, debido a la naturaleza abierta del problema se espera que los requerimientos se perfeccionen con el docente asignado a lo largo del tiempo.

## Normas de Trabajo

Se espera del alumno:

- Empleo del tiempo de consultas en clase para resolver dudas y clarificar el negocio del sistema a construir previo a su diseño.
- Exposición y verificación en clase de la arquitectura propuesta antes de iniciar su implementación.
- Empleo del grupo de correos para realizar consultas que no pudieran ser resueltas en clase.
- Consideración de prácticas distribuidas según lo estudiado en clase para elaborar una arquitectura flexible, escalable y robusta.
- Aprobación del cuerpo docente para el uso de cualquier biblioteca.

## Entrega

- La fecha de entrega es la estipulada en la sección correspondiente del campus.
- Formato de entrega:
  - **Entrega presencial.**
  - Documento de arquitectura 4+1 Views o C4Model incluyendo al menos: diagramas de robustez, despliegue, actividades, paquetes, secuencia y DAG.
  - Listado de tareas a ejecutar y división entre integrantes.
  - No se evaluará código.
