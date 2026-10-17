# Cronograma Letivo

PWA para professores de cursos profissionais. Cada professor mete o seu horário
(turmas, tempos por dia, UC por ordem) e a app gera o cronograma do ano, com as
interrupções letivas, os feriados e os períodos de FCT de cada turma.

Depois do deploy fica em `https://fmaiamalta.github.io/schedify_app/cronograma/`.

## O que faz

- Distribui as UC pelos dias de aula. Quando uma UC acaba a meio de um dia, a
  seguinte começa nesse dia.
- Salta interrupções, feriados, períodos da turma (FCT) e dias sem aula.
- Linha vermelha no dia de hoje e progresso de cada UC (tempos dados até hoje).
- Tarefas por UC, com data e check.
- Catálogo de UC com reconhecimento pelo código (`2634`, `UC02634`). Vem com o
  referencial de Técnico/a de Multimédia e importa outros referenciais em PDF,
  DOCX ou CSV (`código;nome;horas`). As horas das UC vêm dos pontos de crédito:
  2,25 pontos = 25 h = 30 tempos de 50 min.
- Calendário escolar 2026/2027 já preenchido. Importa datas de um PDF ou imagem
  e partilha-se com os colegas por link (`#cal=...`).
- Os dados ficam no dispositivo (localStorage). Exportar e importar cópia em JSON.

## Desenvolvimento

```bash
cd cronograma
npm install
npm run dev      # http://localhost:5173
npm test         # testes do motor, catálogo e calendário
npm run build
```

## Instalar no telemóvel

- iPhone (Safari): Partilhar, depois "Adicionar ao ecrã principal".
- Android (Chrome): menu, depois "Instalar app".
