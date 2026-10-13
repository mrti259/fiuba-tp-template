#import "@preview/sacayan-fiuba:0.1.0": fiuba-tp
#import "@preview/cetz:0.4.0"

#show: fiuba-tp.with(
  titulo: "Wikipedia Article Analysis",
  subtitulo: "TP Diseño — Documento de arquitectura 4+1",
  materia-codigo: "75.74",
  materia-nombre: "Sistemas Distribuidos I",
  catedra: "Cátedra Roca",
  docente: "Prof. Pablo Roca",
  cuatrimestre: "2° cuatrimestre",
  anio: "2026",
  fecha: "13/10/2026",
  autores: (
    (nombre: "Garibotti, Borja", padron: "106124", email: "mgaribotti@fi.uba.ar"),
    (nombre: "Romero Krause, Guido Nadal", padron: "111877", email: "gromerok@fi.uba.ar"),
    (nombre: "Suxo Marca, Juan Cristian", padron: "108280", email: "jsuxo@fi.uba.ar"),
  ),
)

#outline(title: "Índice")

= Contexto y requerimientos

El sistema analiza artículos de Wikipedia en inglés y en francés a partir de un dataset público de Kaggle, que el cliente envía como entrada de todas las consultas. Como referencia del tratamiento de los datos se toma un notebook de ejemplo, y la descarga de imágenes se realiza mediante la API pública de Wikimedia. El procesamiento se despliega en múltiples computadoras que se comunican exclusivamente a través de un middleware propio basado en grupos. Los requerimientos son abiertos y se refinan de forma iterativa junto con el docente.

== Requerimientos funcionales

#table(
  columns: (auto, 1fr, 1fr),
  table.header([Query], [Filtro], [Salida]),
  [Q1], [lang = inglés, año \<= 2020], [(url, fecha de modificación)],
  [Q2], [año \<= 2020, sections contiene biography / biographie], [(nombre, url, imagen en bytes)],
  [Q3], [sin filtro de año; sin stopwords], [palabras únicas en algún abstract en inglés y en algún abstract en francés],
  [Q4], [sin filtro de año; 1 vez por abstract; sin stopwords], [top 20 (palabra, cantidad)],
  [Q5], [base año \<= 2020, resultado año \>= 2021; con repeticiones, sin stopwords], [(url, cantidad de palabras) si cantidad \> promedio base],
)

== Requerimientos no funcionales

- Aislamiento entre clientes: múltiples clientes pueden consultar en simultáneo sin interferir entre sí, y cada uno realiza una única ejecución.
- Optimización para multicomputadoras: el sistema escala agregando nodos, tanto por cantidad de clientes como por volumen de datos por cliente.
- Middleware propio que abstrae la comunicación entre nodos mediante grupos, de modo que ningún nodo conoce la ubicación física de sus pares.
- Cierre ordenado (graceful quit) ante la recepción de SIGTERM, sin perder los mensajes ya aceptados.

== Supuestos

- Cada cliente envía el dataset en lotes y marca el fin del envío con un mensaje EOF.
- Los resultados se emiten de forma incremental: a medida que los nodos procesan los lotes, envían resultados parciales de cada query hacia la cola `Results`, sin esperar el fin de la entrada.
- Q1, Q2 y Q3 pueden responder sobre la marcha: Q1 y Q2 emiten un resultado por artículo filtrado, y Q3 emite cada palabra en cuanto la observa en ambos idiomas, sin esperar el `EOF`. Q4 y Q5, en cambio, no pueden cerrar su resultado hasta el `EOF`: el top 20 y el promedio necesitan haber visto todas las entradas.
- El `Gateway` reenvía al cliente cada resultado apenas lo recibe, en paralelo con la recepción de lotes; la conexión cliente-Gateway es full-duplex.
- Cuando el cliente termina su envío, envía su `EOF`; el `Gateway` deja de escuchar a ese cliente y lo propaga al pipeline. Al terminar de procesar todas las entradas del cliente, cada nodo propaga su propio `EOF`, que libera su estado.
- Los `EOF` de todos los nodos convergen en `EOFBarrier`, un nodo stateful entre la cola `Results` y el `Gateway` que coordina el fin de la ejecución. Al recibir el último `EOF`, determina que no quedarán más resultados y libera el `EOF` hacia el `Gateway`, que lo reenvía al cliente, que deja de esperar. El `EOFBarrier` no filtra ni transforma resultados.
- El tokenizado y las listas de stopwords son iguales para Q3, Q4 y Q5, con listas en inglés y en francés.
- En Q4 cada palabra cuenta una sola vez por abstract; en Q5 el largo del abstract cuenta repeticiones, es decir, el total de tokens.
- En Q4 y Q5 se excluyen las stopwords del conteo.
- Q5 calcula el promedio únicamente sobre los artículos con año \<= 2020 y lo compara con los artículos con año \>= 2021.

= Vista de escenarios

Cada escenario describe una ejecución aislada de un cliente sobre el dataset completo. El `Gateway` acepta la conexión y publica los lotes del cliente; el pipeline procesa cada artículo según la lógica de las queries; finalmente, los nodos terminales publican los cinco resultados (R1–R5), que viajan por la cola `Results` a través del `EOFBarrier` y del `Gateway` hasta el cliente que originó la consulta. Todos los escenarios comparten este patrón y difieren únicamente en el filtro y el procesamiento aplicados.

== Diagrama de casos de uso

#figure(
  cetz.canvas({
    import cetz.draw: *

    rect((-3, 4.3), (3, -4.3), name: "sys")
    content((0, 3.9), text(size: 9pt)[*Wikipedia Article Analysis*])

    circle((0, 2.6), radius: (2.4, 0.53), name: "q1")
    content("q1", text(size: 7.5pt)[Q1 — artículos EN \<= 2020])
    circle((0, 1.3), radius: (2.4, 0.53), name: "q2")
    content("q2", text(size: 7.5pt)[Q2 — biografías + imagen])
    circle((0, 0), radius: (2.4, 0.53), name: "q3")
    content("q3", text(size: 7.5pt)[Q3 — vocabulario EN–FR])
    circle((0, -1.3), radius: (2.4, 0.53), name: "q4")
    content("q4", text(size: 7.5pt)[Q4 — top 20 palabras])
    circle((0, -2.6), radius: (2.4, 0.53), name: "q5")
    content("q5", text(size: 7.5pt)[Q5 — artículos largos \>= 2021])

    circle((-5.2, 3.2), radius: 0.28)
    line((-5.2, 2.92), (-5.2, 1.6))
    line((-5.75, 2.4), (-4.65, 2.4))
    line((-5.2, 1.6), (-5.6, 0.7))
    line((-5.2, 1.6), (-4.8, 0.7))
    content((-5.2, 0.25), text(size: 7.5pt)[Cliente])

    line((-4.65, 2.55), "q1.west")
    line((-4.65, 2.2), "q2.west")
    line((-4.65, 1.85), "q3.west")
    line((-4.65, 1.5), "q4.west")
    line((-4.65, 1.15), "q5.west")

    circle((5.2, 2.2), radius: 0.28)
    line((5.2, 1.92), (5.2, 0.6))
    line((4.65, 1.4), (5.75, 1.4))
    line((5.2, 0.6), (4.8, -0.3))
    line((5.2, 0.6), (5.6, -0.3))
    content((5.2, -0.75), text(size: 7.5pt)[Internet])

    line("q2.east", (4.65, 1.3))
  }),
  caption: [Casos de uso: `Cliente` ejecuta Q1–Q5; `Internet` (Wikimedia) participa solo en Q2 mediante la descarga de imágenes.],
)

Cada caso de uso corresponde a una query de esta sección: Q1–Q2 filtran por año \<= 2020 (R1–R2) y Q3–Q5 procesan abstracts de todo el corpus (R3–R5). El `Cliente` inicia la ejecución enviando el dataset por lotes y recibe los resultados por la cola `Results`.

== Q1 — artículos en inglés hasta 2020

- *Filtro y procesamiento:* idioma inglés y año \<= 2020. No hay procesamiento de texto.
- *Salida:* un par (url, fecha de modificación) por artículo que pasa el filtro.

== Q2 — biografías hasta 2020

- *Filtro y procesamiento:* año \<= 2020 y sección biography (inglés) o biographie (francés). Cada biografía se enriquece con la descarga de su imagen desde Wikimedia, a cargo de `ImageFetcher`.
- *Salida:* una terna (nombre, url, imagen en bytes) por biografía.
== Q3 — vocabulario compartido EN–FR

- *Filtro y procesamiento:* tokenizado de cada abstract sin stopwords (listas de inglés y francés).
- *Salida:* las palabras únicas presentes tanto en algún abstract en inglés como en algún abstract en francés.
== Q4 — top 20 palabras de abstracts

- *Filtro y procesamiento:* tokenizado sin stopwords; cada palabra cuenta una sola vez por abstract.
- *Salida:* los 20 pares (palabra, cantidad) más frecuentes.

== Q5 — artículos largos desde 2021

- *Filtro y procesamiento:* se calcula el promedio de palabras por abstract sobre los artículos con año \<= 2020, contando repeticiones y sin stopwords; ese promedio se compara con el largo de cada artículo con año \>= 2021, medido con el mismo criterio.
- *Salida:* pares (url, cantidad de palabras) para los artículos posteriores cuyo largo supera el promedio base.

= Vista lógica

== Diagrama de robustez

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Robustez.drawio.png", width: 100%),
  caption: [Robustez: boundary `Gateway`, controles de ruteo/filtrado/agregación y coordinación (`EOFBarrier`), y entidades que son colas. `ImageFetcher` es el único control que accede a actor externo `Internet`.],
)

`Gateway` es el único boundary del sistema: recibe los lotes y el EOF de cada cliente y los publica en la cola `entries`. A partir de ahí, once controles procesan los mensajes, cada uno con un rol acotado:

- *Ruteo:* `EntryRouter` clasifica los artículos por año y por presencia de abstract; `YearRouter` divide el conteo de palabras por año.
- *Filtrado:* `Q1Q2FilterMap` resuelve los filtros de Q1 y Q2; `Q5Filter` compara el largo de cada artículo con el promedio.
- *Enriquecimiento:* `ImageFetcher` descarga la imagen de cada biografía desde Wikimedia.
- *Tokenizado:* `AbstractTokenizer` convierte cada abstract en streams de palabras y conteos.
- *Agregación:* `IntersectionAggregator` (Q3), `WordFrequencyAggregator` y `Top20Reducer` (Q4) y `AverageCalculator` (Q5) acumulan estado hasta recibir el EOF.
- *Coordinación:* `EOFBarrier` coordina el fin de la ejecución.

Las entidades son colas del middleware, cada una con un payload acotado:

#figure(
  table(
    columns: (auto, 1fr, auto, auto),
    table.header([Cola], [Payload], [Clave de sharding], [Queries]),
    [`entries`], [`(abstract, lang, date, url)`], [—], [todas],
    [`<= 2020 entries`], [`(url, date, lang, sections, name, image_url)`], [—], [Q1, Q2],
    [`has_abstract entries`], [artículo con abstract], [—], [Q3, Q4, Q5],
    [`words` (Q3)], [`(word, lang)`], [`(word, client_id)`], [Q3],
    [`words` (Q4)], [`(word)`], [`(word, client_id)`], [Q4],
    [`abstract word count`], [`(url, count, date)`], [—], [Q5],
    [`words frequencies`], [`(word, freq)`], [—], [Q4],
    [`<= 2020 counts`], [`(url, count, date)`], [—], [Q5],
    [`>= 2021 counts`], [`(url, count, date)`], [—], [Q5],
    [`avg calculations`], [`(avg)`], [—], [Q5],
    [`Q2 partial results`], [`(name, url, image_url)`], [—], [Q2],
    [`Results` (parciales)], [resultados `R1`–`R5` hacia `EOFBarrier`], [—], [todas (nodos terminales)],
    [`Results` (finales)], [resultados `R1`–`R5` hacia `Gateway`], [—], [todas (vía `EOFBarrier`)],
  ),
  caption: [Entidades del diagrama de robustez: colas del middleware con su payload, su clave de sharding y las queries que las consumen.],
)

Los agregadores de palabras se shardan por `(word, client_id)`, mientras que `Top20Reducer`, `AverageCalculator`, `Q5Filter` y `EOFBarrier` se shardan por `(client_id)`. Estas claves aíslan el estado entre clientes y, en el caso de los agregadores de palabras, permiten paralelizar el procesamiento particionando el vocabulario.

= Vista de desarrollo

== Diagrama de paquetes

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Paquetes simplified.drawio.png", width: 90%),
  caption: [Paquetes: `client`, `gateway`, `worker` e `internal`/`common`. Dependencias acíclicas hacia `middleware` y `protocol`.],
)

- Cada ejecutable (`gateway`, `worker` y `client`) se compone de su `main` y su `config`.
- `internal` de cada ejecutable contiene `sender` y `receiver`; en `gateway` añade `controller`, y en `worker` añade `core` (lógica de grupos, manejo de EOF y graceful quit) y `persistence` (estado local de agregadores y barrera).
- `common` contiene:
  - `network`/`protocol`, que define el formato de mensajes y la serialización;
  - `middleware`, un wrapper sobre RabbitMQ en el que cada grupo se modela con exchanges y colas;
  - `persistence`, `utils` y `core`, compartidos por todos los nodos.
- `config` (parámetros, logging y manejo de SIGTERM) es transversal a todos los paquetes.
- Los agregadores, `Q5Filter` y la barrera son `<<stateful>>`; el resto de los nodos es stateless.

== DAG del pipeline

#figure(
  image("../diagrams/Distribuidos - TP Diseño-DAG.drawio.png", width: 95%),
  caption: [DAG: `EntryRouter` raíz; rama Q1/Q2 a la izquierda, rama Q3/Q4/Q5 a la derecha. Gris = stateless replicable, azul = stateful shardeado. `EOFBarrier` stateful al fondo, donde convergen todas las ramas.],
)

El pipeline está formado por los nodos de cómputo del DAG, con el `EOFBarrier` stateful como punto final común. `EntryRouter` es la raíz del DAG: separa el procesamiento en dos ramas. La rama Q1/Q2 rutea los artículos con año \<= 2020 hacia `Q1Q2FilterMap`, que resuelve el filtro de inglés para R1 y el de biografías para R2. La rama Q3/Q4/Q5 rutea los artículos con abstract hacia `AbstractTokenizer`, que emite tres streams en paralelo:

- *Stream Q3:* `(word, lang)` con `key=(word, client_id)` hacia `IntersectionAggregator`.
- *Stream Q4:* `(word)` con `key=(word, client_id)` hacia `WordFrequencyAggregator` y de ahí a `Top20Reducer` con `key=(client_id)`.
- *Stream Q5:* `(url, count, date)` hacia `YearRouter`, que divide en año \<= 2020 (hacia `AverageCalculator`) y año \>= 2021 (directo a `Q5Filter`); el promedio entra a `Q5Filter` con `key=(client_id)`.

Los nodos terminales publican sus resultados en la cola `Results`, que alimenta al `EOFBarrier`. Por legibilidad, el DAG muestra solo los nodos de cómputo: cada arista es un grupo del middleware (una cola), por lo que las colas intermedias (`Q2 partial results`, `words`, `counts`, `Results`, etc.) no se dibujan como nodos propios.

= Vista de procesos

La comunicación entre nodos es siempre a través del middleware de grupos: cada arista del DAG es un grupo, implementado como un exchange más una cola. El protocolo define lotes de datos para las entradas, mensajes `EOF` identificados por `client_id` que disparan el cierre en cascada, y resultados `R1`–`R5` que viajan por la cola `Results` hacia el `EOFBarrier`.

== Actividades por query

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Actividades-Q1.drawio.png", width: 85%),
  caption: [Actividad Q1: `EntryRouter` publica lote `<= 2020`; `Q1Q2FilterMap` filtra idioma inglés y publica resultado o descarta.],
)

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Actividades-Q2.drawio.png", width: 85%),
  caption: [Actividad Q2: rama biografías; `Q1Q2FilterMap` filtra `has_biography` y `ImageFetcher` descarga la imagen antes de publicar.],
)

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Actividades-Q3.drawio.png", width: 85%),
  caption: [Actividad Q3: tokenizado, emisión `(word, lang)` e intersección EN–FR en `IntersectionAggregator`.],
)

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Actividades-Q4.drawio.png", width: 85%),
  caption: [Actividad Q4: conteo una vez por abstract, agregación de frecuencias y cálculo del top 20.],
)

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Actividades-Q5.drawio.png", width: 85%),
  caption: [Actividad Q5: `YearRouter` separa base `<= 2020` y candidatos `>= 2021` por largo con repeticiones (sin stopwords); `AverageCalculator` difunde el promedio y `Q5Filter` compara.],
)

== Secuencias

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Secuencia.drawio.png", width: 100%),
  caption: [Secuencia general: `Gateway` → `EntryRouter` → ramas Q1/Q2 y Q3/Q4/Q5; acumulación de estado, propagación de EOF y barrera final (`EOFBarrier`) hasta R4/R5. El retorno hacia el cliente se dibuja simplificado: en la implementación viaja por `Results` y lo reenvía el `Gateway`.],
)

En la rama Q1/Q2, el `Gateway` envía los lotes en un bucle; `EntryRouter` rutea los artículos con año \<= 2020 hacia `Q1Q2FilterMap`, que separa R1 (artículos en inglés) de R2 (biografías, con la descarga de la imagen a cargo de `ImageFetcher`). Cada resultado se publica en la cola `Results` y el EOF cierra cada query en orden. Los `EOF` de esta rama también convergen en `EOFBarrier` (omitida en este diagrama; ver la secuencia general).

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Secuencia-Q1_Q2.drawio.png", width: 90%),
  caption: [Secuencia Q1–Q2: `Gateway`, `EntryRouter`, `Q1Q2FilterMap`, `ImageFetcher` e `Internet` (Wikimedia). Diagrama simplificado: R1–R2 viajan por `Results` y la propagación de `EOF` hacia `EOFBarrier` se omite (ver secuencia general).],
)

En la rama Q3/Q4/Q5, `EntryRouter` envía los artículos con abstract hacia `AbstractTokenizer`, que tokeniza cada lote y emite tres streams:

- *Stream Q3:* pares `(word, lang)` hacia `IntersectionAggregator`, que verifica la presencia de cada palabra en ambos idiomas.
- *Stream Q4:* palabras `(word)` hacia `WordFrequencyAggregator`; al llegar el EOF, `Top20Reducer` calcula el top 20.
- *Stream Q5:* `(url, count, date)` hacia `YearRouter`, que envía las entradas con año \<= 2020 a `AverageCalculator` y las entradas con año \>= 2021 directo a `Q5Filter`, que recibe largos y promedio final.

Los mensajes EOF se propagan por rama para liberar el estado acumulado por `client_id`.

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Secuencia-Q3_Q4_Q5.drawio.png", width: 100%),
  caption: [Secuencia Q3–Q5: tokenizado, agregadores shardeados, cálculo de promedio y filtrado final. Propagación explícita de EOF hacia `EOFBarrier`.],
)

= Vista física

#figure(
  image("../diagrams/Distribuidos - TP Diseño-Despliegue simplified.drawio.png", width: 95%),
  caption: [Despliegue: N clientes, 1 `Gateway Server`, 1 `Middleware` (RabbitMQ) y M `Worker Nodes` replicables.],
)

- `Client`: N instancias, una por máquina de cliente.
- `Gateway Server`: una única réplica por despliegue; concentra la admisión de clientes y el ruteo inicial, y es el único punto con estado de conexión por cliente.
- `Middleware`: RabbitMQ centralizado, con un exchange por grupo y una cola por consumidor; abstrae los grupos y aporta persistencia y redelivery.
- `Worker Node`: M réplicas; cada worker ejecuta un subconjunto de los nodos del DAG.

== Escalado

- *Escalado por clientes:* sumar workers stateless no redistribuye estado; los stateful añaden particiones por `client_id`, y el EOF de cada cliente libera su estado sin afectar al resto.
- *Escalado por volumen:* `AbstractTokenizer`, `Q1Q2FilterMap` e `ImageFetcher` escalan horizontalmente añadiendo consumidores del mismo grupo, mientras que `WordFrequencyAggregator` e `IntersectionAggregator` escalan por cardinalidad del vocabulario.
- *Graceful quit:* ante SIGTERM, cada nodo deja de consumir, termina el lote en curso, hace ack y cierra; RabbitMQ retiene los mensajes no confirmados para la siguiente réplica.

= Listado de tareas y división

La estimación de cada tarea se expresa en puntos de historia (escala Fibonacci). La asignación de responsables queda pendiente de definir por el grupo. Los componentes son los del diagrama de robustez: cada nodo terminal incluye la emisión de sus resultados R1–R5. Las tareas se agrupan en etapas según sus dependencias: cada etapa requiere que la anterior esté completa; `Transversal` acompaña todo el desarrollo.

#figure(
  table(
    columns: (auto, 1fr, auto, auto),
    table.header([Etapa], [Componente], [Est. (SP)], [Depende de]),

    [Etapa 0], [Middleware de grupos], [13], [—],
    [Etapa 0], [Protocolo y serialización (lotes, EOF, R1–R5)], [8], [—],
    [Etapa 0], [Config, logging y graceful quit (SIGTERM)], [5], [—],

    [Etapa 1], [Cliente (dataset, lotes + EOF, recepción de resultados)], [8], [Protocolo, Middleware],
    [Etapa 1], [Gateway (admisión full-duplex, `entries`, reenvío de resultados)], [8], [Middleware, Protocolo],
    [Etapa 1], [EntryRouter], [3], [Middleware, Protocolo],
    [Etapa 1], [AbstractTokenizer], [8], [Middleware, Protocolo],

    [Etapa 2], [Q1Q2FilterMap], [5], [EntryRouter],
    [Etapa 2], [YearRouter], [2], [AbstractTokenizer],
    [Etapa 2], [ImageFetcher (API Wikimedia)], [5], [Q1Q2FilterMap],
    [Etapa 2], [IntersectionAggregator (Q3)], [5], [AbstractTokenizer],
    [Etapa 2], [WordFrequencyAggregator (Q4)], [5], [AbstractTokenizer],
    [Etapa 2], [AverageCalculator (Q5)], [5], [YearRouter],

    [Etapa 3], [Top20Reducer (Q4)], [3], [WordFrequencyAggregator],
    [Etapa 3], [Q5Filter (Q5)], [3], [AverageCalculator, YearRouter],
    [Etapa 3], [EOFBarrier y propagación de EOF], [8], [EOF de todos los nodos],

    [Transversal], [Tests de integración y dataset de prueba], [8], [todas las etapas],
    [Transversal], [Despliegue (RabbitMQ + workers)], [5], [todas las etapas],
  ),
  caption: [Tareas de implementación agrupadas por etapa según sus dependencias, estimadas en puntos de historia.],
)

#figure(
  table(
    columns: (1fr, auto),
    table.header([Etapa], [Total (SP)]),
    [Etapa 0 — base], [26],
    [Etapa 1 — ingesta], [27],
    [Etapa 2 — filtrado y agregación], [27],
    [Etapa 3 — reducción y cierre], [14],
    [Transversal], [13],
  ),
  caption: [Carga estimada por etapa: 107 SP en total.],
)
