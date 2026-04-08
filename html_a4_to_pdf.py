from html.parser import HTMLParser
from pathlib import Path
import textwrap

class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts=[]
        self.break_tags={"p","div","section","header","footer","h1","h2","h3","li","br"}
    def handle_starttag(self, tag, attrs):
        if tag in self.break_tags:
            self.parts.append("\n")
    def handle_endtag(self, tag):
        if tag in self.break_tags:
            self.parts.append("\n")
    def handle_data(self, data):
        t=data.strip()
        if t:
            self.parts.append(t+" ")

def pdf_escape(text:str)->str:
    return text.replace('\\','\\\\').replace('(','\\(').replace(')','\\)')

def make_pdf(lines, out:Path):
    width,height=595,842
    margin=40
    leading=11
    y=height-margin

    content=["BT", "/F1 9 Tf"]
    for line in lines:
        if y < margin:
            break
        content.append(f"1 0 0 1 {margin} {int(y)} Tm ({pdf_escape(line)}) Tj")
        y -= leading
    content.append("ET")
    stream="\n".join(content).encode('latin-1','replace')

    objs=[]
    objs.append(b"1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n")
    objs.append(b"2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n")
    objs.append(f"3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 {width} {height}] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj\n".encode())
    objs.append(b"4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n")
    objs.append(f"5 0 obj << /Length {len(stream)} >> stream\n".encode()+stream+b"\nendstream endobj\n")

    pdf=b"%PDF-1.4\n"
    offsets=[0]
    for o in objs:
        offsets.append(len(pdf))
        pdf+=o
    xref_start=len(pdf)
    pdf+=f"xref\n0 {len(offsets)}\n".encode()
    pdf+=b"0000000000 65535 f \n"
    for off in offsets[1:]:
        pdf+=f"{off:010d} 00000 n \n".encode()
    pdf+=f"trailer << /Size {len(offsets)} /Root 1 0 R >>\nstartxref\n{xref_start}\n%%EOF\n".encode()
    out.write_bytes(pdf)

html=Path('infografia_joaquin.html').read_text(encoding='utf-8')
parser=TextExtractor(); parser.feed(html)
text=''.join(parser.parts)
text=' '.join(text.split())
wrapped=textwrap.wrap(text, width=105)
make_pdf(wrapped, Path('infografia_joaquin_A4.pdf'))
print('PDF generado: infografia_joaquin_A4.pdf')
