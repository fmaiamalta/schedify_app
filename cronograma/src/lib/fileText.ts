// Extrai texto de PDF, DOCX, imagem (OCR) ou ficheiro de texto. As bibliotecas
// pesadas só são carregadas quando são precisas.

export async function textoDoFicheiro(file: File, progresso?: (msg: string) => void): Promise<string> {
  const nome = file.name.toLowerCase();
  if (file.type === 'application/pdf' || nome.endsWith('.pdf')) return textoDePDF(file);
  if (nome.endsWith('.docx')) return textoDeDOCX(file);
  if (file.type.startsWith('image/')) return textoDeImagem(file, progresso);
  return file.text();
}

async function textoDePDF(file: File): Promise<string> {
  const pdfjs = await import('pdfjs-dist');
  const workerUrl = (await import('pdfjs-dist/build/pdf.worker.min.mjs?url')).default;
  pdfjs.GlobalWorkerOptions.workerSrc = workerUrl;
  const doc = await pdfjs.getDocument({ data: await file.arrayBuffer() }).promise;
  const paginas: string[] = [];
  for (let p = 1; p <= doc.numPages; p++) {
    const page = await doc.getPage(p);
    const content = await page.getTextContent();
    // Agrupa os pedaços de texto por linha (mesma coordenada y).
    const linhas = new Map<number, { x: number; s: string }[]>();
    for (const item of content.items) {
      if (!('str' in item) || !item.str.trim()) continue;
      const y = Math.round(item.transform[5]);
      const chave = [...linhas.keys()].find((k) => Math.abs(k - y) <= 2) ?? y;
      if (!linhas.has(chave)) linhas.set(chave, []);
      linhas.get(chave)!.push({ x: item.transform[4], s: item.str });
    }
    const ordenadas = [...linhas.entries()].sort((a, b) => b[0] - a[0]);
    paginas.push(ordenadas.map(([, partes]) => partes.sort((a, b) => a.x - b.x).map((p) => p.s).join(' ')).join('\n'));
  }
  return paginas.join('\n');
}

async function textoDeDOCX(file: File): Promise<string> {
  const JSZip = (await import('jszip')).default;
  const zip = await JSZip.loadAsync(await file.arrayBuffer());
  const xml = await zip.file('word/document.xml')?.async('string');
  if (!xml) return '';
  const paragrafos = xml.match(/<w:p[ >][\s\S]*?<\/w:p>/g) ?? [];
  return paragrafos
    .map((p) => (p.match(/<w:t[^>]*>([^<]*)<\/w:t>/g) ?? []).map((t) => t.replace(/<[^>]+>/g, '')).join(''))
    .map((t) => t.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'"))
    .filter((t) => t.trim())
    .join('\n');
}

async function textoDeImagem(file: File, progresso?: (msg: string) => void): Promise<string> {
  progresso?.('A ler a imagem (pode demorar 20 a 40 segundos)...');
  const { createWorker } = await import('tesseract.js');
  const worker = await createWorker('por');
  try {
    const { data } = await worker.recognize(file);
    return data.text;
  } finally {
    await worker.terminate();
  }
}
