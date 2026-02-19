# PR Workflow for Maintainers

Esta es la fuente de verdad para el flujo de mantenimiento de PRs.

## Orden de procesamiento

Procesar PRs **de más antiguo a más nuevo**.

## Regla de trabajo

Skills ejecutan el workflow. El agente provee juicio.
Pausar entre skills para evaluar dirección técnica.

Orden obligatorio de uso:

1. `review-pr` — solo revisión, produce findings
2. `prepare-pr` — rebase, fix, gate, push al branch head del PR
3. `merge-pr` — squash-merge, verificar estado MERGED, limpiar

## Flujo unificado

### 1) `review-pr`

Propósito: revisar solo, producir findings estructurados.

Output esperado:
- Recomendación: ready, needs work, needs discussion, o close.
- `.local/review.md` con findings accionables.

Checkpoint antes de `prepare-pr`:
```
¿Qué problema intenta resolverse?
¿Cuál es la implementación más óptima?
¿Podemos arreglar todo?
¿Hay preguntas?
```

### 2) `prepare-pr`

Propósito: dejar el PR listo para merge en su head branch.

Output esperado:
- Código y tests actualizados en el head branch del PR.
- `.local/prep.md` con cambios, verificación y HEAD SHA actual.
- Estado final: `PR is ready for /merge-pr`.

Checkpoint antes de `merge-pr`:
```
¿Es esta la implementación más óptima?
¿Está el código bien tipado?
¿Hay suficientes tests?
¿Hay regresiones?
¿Hay vulnerabilidades de seguridad?
```

### 3) `merge-pr`

Propósito: merge solo después de que review y prep están completos y los checks están en verde.

Output esperado:
- Merge commit exitoso y SHA registrado.
- Limpieza del worktree.
- Comentario en el PR indicando merge exitoso.

## Reglas de calidad

- No confiar en el código del PR por defecto.
- No mergear cambios que no puedas validar.
- Mantener tipos estrictos. No usar `any` en código de implementación.
- Fixes deben resolver causas raíz, no síntomas locales.
- Siempre evaluar impacto de seguridad.

## Reglas de commit

- Formato: `fix: <summary> (repo#<PR>) thanks @<pr-author>`
- Changelog siempre requerido.
- Co-author trailers para autor del PR y reviewer.

## Scripts rápidos

```sh
scripts/pr-review <PR>
scripts/pr-prepare run <PR>
scripts/pr-merge run <PR>
```
