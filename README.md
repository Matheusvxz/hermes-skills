# Hermes Skills

Template inicial para criação de skills no Hermes, com um exemplo completo e seguindo boas práticas.

## Estrutura recomendada

```text
skills/
  exemplo-inicial/
    README.md
    skill.yaml
    prompt.md
    input.schema.json
    output.schema.json
    examples.json
```

## Como usar

1. Copie `skills/exemplo-inicial` para uma nova pasta da sua skill.
2. Ajuste `skill.yaml` com metadados reais.
3. Atualize `prompt.md` com instruções específicas da skill.
4. Defina contratos de entrada e saída em `input.schema.json` e `output.schema.json`.
5. Mantenha exemplos reais em `examples.json` para facilitar validação e evolução.