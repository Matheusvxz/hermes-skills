# Skill: Exemplo Inicial

Este diretório funciona como template base para novas skills do Hermes.

## Boas práticas aplicadas

- Nome e ID claros no `skill.yaml`.
- Prompt separado em `prompt.md`.
- Contratos formais com JSON Schema (`input.schema.json` e `output.schema.json`).
- Exemplos versionáveis em `examples.json`.
- Saída estruturada e previsível.

## Fluxo recomendado

1. Validar entrada contra `input.schema.json`.
2. Executar a lógica descrita em `prompt.md`.
3. Retornar sempre no formato definido em `output.schema.json`.
