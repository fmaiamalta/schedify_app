import { isValidISO } from './dates';
import type { ISODate } from './types';

export interface SugestaoCalendario {
  inicio?: ISODate;
  fim?: ISODate;
  interrupcoes: { nome: string; inicio: ISODate; fim: ISODate }[];
  feriados: { nome: string; data: ISODate }[];
}

const MESES: Record<string, number> = {
  janeiro: 1, fevereiro: 2, marco: 3, abril: 4, maio: 5, junho: 6,
  julho: 7, agosto: 8, setembro: 9, outubro: 10, novembro: 11, dezembro: 12,
};

const NOMES_INTERRUPCAO: [RegExp, string][] = [
  [/natal/i, 'Natal'],
  [/carnaval/i, 'Carnaval'],
  [/p[aá]scoa/i, 'Páscoa'],
  [/interrup/i, 'Interrupção'],
];

const NOMES_FERIADO: [RegExp, string][] = [
  [/implanta[cç][aã]o/i, 'Implantação da República'],
  [/todos os santos/i, 'Todos os Santos'],
  [/restaura[cç][aã]o/i, 'Restauração da Independência'],
  [/imaculada/i, 'Imaculada Conceição'],
  [/ano novo/i, 'Ano Novo'],
  [/sexta.feira santa/i, 'Sexta-feira Santa'],
  [/25 de abril|liberdade/i, 'Dia da Liberdade'],
  [/trabalhador/i, 'Dia do Trabalhador'],
  [/corpo de deus/i, 'Corpo de Deus'],
  [/dia de portugal/i, 'Dia de Portugal'],
  [/municipal/i, 'Feriado municipal'],
  [/feriado/i, 'Feriado'],
];

function semAcentos(s: string): string {
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
}

/** Ano civil de um mês dentro do ano letivo que começa em setembro de anoInicial. */
function anoDoMes(mes: number, anoInicial: number): number {
  return mes >= 8 ? anoInicial : anoInicial + 1;
}

function montar(d: number, m: number, a: number | undefined, anoInicial: number): ISODate | undefined {
  let ano = a ?? anoDoMes(m, anoInicial);
  if (ano < 100) ano += 2000;
  const iso = `${ano}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
  return isValidISO(iso) ? iso : undefined;
}

// "16/12", "16/12/2026", "16-12-26", "16 de dezembro", "16 de dezembro de 2026"
const DATA = String.raw`(\d{1,2})\s*(?:[/.-]\s*(\d{1,2})(?:\s*[/.-]\s*(\d{2,4}))?|\s+de\s+([a-zç]+)(?:\s+de\s+(\d{4}))?)`;
const SEP = String.raw`\s*(?:a|até|ao|–|—|-)\s*`;

function lerData(g: string[], off: number, anoInicial: number): ISODate | undefined {
  const d = Number(g[off]);
  if (g[off + 1]) return montar(d, Number(g[off + 1]), g[off + 2] ? Number(g[off + 2]) : undefined, anoInicial);
  const mes = MESES[semAcentos(g[off + 3] ?? '')];
  if (!mes) return undefined;
  return montar(d, mes, g[off + 4] ? Number(g[off + 4]) : undefined, anoInicial);
}

/**
 * Procura datas num texto de calendário escolar. O resultado é só uma
 * sugestão: a pessoa confirma tudo antes de gravar.
 */
export function lerCalendario(texto: string, anoInicial: number): SugestaoCalendario {
  const out: SugestaoCalendario = { interrupcoes: [], feriados: [] };
  const plano = texto.replace(/ /g, ' ');
  const linhas = plano.split(/\r?\n/);

  const reIntervalo = new RegExp(DATA + SEP + DATA, 'gi');
  const reData = new RegExp(DATA, 'gi');

  for (let i = 0; i < linhas.length; i++) {
    const linha = linhas[i];
    const contexto = `${linhas[i - 1] ?? ''} ${linha}`;
    const usados: [number, number][] = [];

    let m: RegExpExecArray | null;
    reIntervalo.lastIndex = 0;
    while ((m = reIntervalo.exec(linha))) {
      const inicio = lerData(m as unknown as string[], 1, anoInicial);
      const fim = lerData(m as unknown as string[], 6, anoInicial);
      if (!inicio || !fim || fim < inicio) continue;
      usados.push([m.index, m.index + m[0].length]);
      // O nome mais próximo antes do intervalo (ex.: "Natal 16/12–31/12").
      const antes = linha.slice(0, m.index);
      const alvo = antes.trim() ? antes : contexto;
      const nome = ultimoNome(alvo, NOMES_INTERRUPCAO);
      if (nome) {
        if (!out.interrupcoes.some((x) => x.inicio === inicio && x.fim === fim)) {
          out.interrupcoes.push({ nome, inicio, fim });
        }
      } else if (/per[ií]odo|semestre|ano letivo|atividades letivas|aulas/i.test(contexto)) {
        if (!out.inicio || inicio < out.inicio) out.inicio = inicio;
        if (!out.fim || fim > out.fim) out.fim = fim;
      }
    }

    reData.lastIndex = 0;
    while ((m = reData.exec(linha))) {
      const idx = m.index;
      if (usados.some(([a, b]) => idx >= a && idx < b)) continue;
      const data = lerData(m as unknown as string[], 1, anoInicial);
      if (!data) continue;
      const depois = linha.slice(idx + m[0].length, idx + m[0].length + 60);
      const antes = linha.slice(Math.max(0, idx - 60), idx);
      const nome =
        ultimoNome(`${antes} ${depois}`, NOMES_FERIADO.slice(0, -1)) ??
        ultimoNome(`${antes} ${depois}`, NOMES_FERIADO.slice(-1));
      if (nome && !out.feriados.some((f) => f.data === data)) out.feriados.push({ nome, data });
      else if (/in[ií]cio/i.test(antes) && (!out.inicio || data < out.inicio)) out.inicio = data;
    }
  }
  out.interrupcoes.sort((a, b) => a.inicio.localeCompare(b.inicio));
  out.feriados.sort((a, b) => a.data.localeCompare(b.data));
  return out;
}

function ultimoNome(texto: string, nomes: [RegExp, string][]): string | undefined {
  let melhor: { pos: number; nome: string } | undefined;
  for (const [re, nome] of nomes) {
    const g = new RegExp(re.source, 'gi');
    let m: RegExpExecArray | null;
    while ((m = g.exec(texto))) {
      if (!melhor || m.index > melhor.pos) melhor = { pos: m.index, nome };
    }
  }
  return melhor?.nome;
}
