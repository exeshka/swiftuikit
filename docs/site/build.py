#!/usr/bin/env python3
"""Static site generator of the swiftuikit docs. Python 3 stdlib only.

    python3 docs/site/build.py          # builds docs/site/dist/
    python3 docs/site/build.py --serve  # ... and serves it on http://localhost:8000

Pages are written in content/**/*.md (see README.md). Parameter tables are extracted from the dartdoc of lib/src/**.
"""
import html, json, os, re, shutil, sys, glob

HERE = os.path.dirname(os.path.abspath(__file__))
CONTENT = os.path.join(HERE, 'content')
ASSETS = os.path.join(HERE, 'assets')
DIST = os.path.join(HERE, 'dist')
LIB = os.path.abspath(os.path.join(HERE, '..', '..', 'lib'))
esc = html.escape

# ───────────────────────── markdown ─────────────────────────
DART_KW = set('abstract as async await break case catch class const continue default do else enum extends false final finally for if implements import in is late new null override required return static super switch this throw true try var void while with yield get set typedef'.split())
TOKEN = re.compile(r"""(?P<c>//[^\n]*|/\*.*?\*/)|(?P<s>r?'(?:\\.|[^'\\\n])*'|r?"(?:\\.|[^"\\\n])*")|(?P<n>\b\d+(?:\.\d+)?\b)|(?P<w>[A-Za-z_]\w*)""", re.S)


def highlight(code, lang):
    if lang not in ('dart', 'yaml', 'bash', ''):
        return esc(code)
    if lang == 'bash':
        return re.sub(r'(#[^\n]*)', r'<span class="tc">\1</span>', esc(code))
    out, pos = [], 0
    for m in TOKEN.finditer(code):
        out.append(esc(code[pos:m.start()]))
        t = esc(m.group(0))
        if m.group('c'): out.append(f'<span class="tc">{t}</span>')
        elif m.group('s'): out.append(f'<span class="ts">{t}</span>')
        elif m.group('n'): out.append(f'<span class="tn">{t}</span>')
        else:
            w = m.group('w')
            if w in DART_KW and lang == 'dart': out.append(f'<span class="tk">{t}</span>')
            elif w[0].isupper() and lang == 'dart': out.append(f'<span class="tt">{t}</span>')
            else: out.append(t)
        pos = m.end()
    out.append(esc(code[pos:]))
    return ''.join(out)


def inline(s):
    s = esc(s, quote=False)
    codes = []
    def keep(m):
        codes.append(m.group(1)); return f'\x00{len(codes)-1}\x00'
    s = re.sub(r'`([^`]+)`', keep, s)
    s = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', s)
    s = re.sub(r'(?<![\w*])\*([^*\n]+)\*(?![\w*])', r'<em>\1</em>', s)
    s = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', lambda m: f'<a href="{LINKFIX(m.group(2))}">{m.group(1)}</a>', s)
    return re.sub(r'\x00(\d+)\x00', lambda m: f'<code>{codes[int(m.group(1))]}</code>', s)


def LINKFIX(u):  # links between pages: ../widgets/foo.md -> ../widgets/foo.html
    return re.sub(r'\.md(#|$)', r'.html\1', u)


def md(text):
    lines, out, i = text.split('\n'), [], 0
    para = []
    def flush():
        if para: out.append('<p>' + inline(' '.join(para)) + '</p>'); para.clear()
    while i < len(lines):
        l = lines[i]
        if l.startswith('```'):
            flush(); lang = l[3:].strip(); i += 1; buf = []
            while i < len(lines) and not lines[i].startswith('```'): buf.append(lines[i]); i += 1
            i += 1
            code = '\n'.join(buf)
            out.append(f'<div class="code"><button class="copy" type="button" title="Копировать">Copy</button><pre><code>{highlight(code, lang)}</code></pre></div>')
            continue
        m = re.match(r'(#{1,4}) (.*)', l)
        if m:
            flush(); n = len(m.group(1)); t = m.group(2)
            sid = re.sub(r'[^\w]+', '-', t.lower()).strip('-')
            out.append(f'<h{n} id="{sid}">{inline(t)}</h{n}>'); i += 1; continue
        if l.startswith('|') and i + 1 < len(lines) and re.match(r'\|[\s:|-]+\|?$', lines[i + 1]):
            flush(); rows = []
            while i < len(lines) and lines[i].startswith('|'):
                rows.append([c.strip() for c in lines[i].strip().strip('|').split('|')]); i += 1
            head, body = rows[0], rows[2:]
            out.append('<div class="tablewrap"><table><thead><tr>' + ''.join(f'<th>{inline(c)}</th>' for c in head) + '</tr></thead><tbody>' +
                       ''.join('<tr>' + ''.join(f'<td>{inline(c)}</td>' for c in r) + '</tr>' for r in body) + '</tbody></table></div>')
            continue
        if re.match(r'\s*([-*]|\d+\.) ', l):
            flush(); ordered = bool(re.match(r'\s*\d+\.', l)); items = []
            while i < len(lines) and re.match(r'\s*([-*]|\d+\.) ', lines[i]):
                items.append(re.sub(r'^\s*([-*]|\d+\.) ', '', lines[i])); i += 1
                while i < len(lines) and lines[i].startswith('   ') and not re.match(r'\s*([-*]|\d+\.) ', lines[i]):
                    items[-1] += ' ' + lines[i].strip(); i += 1
            tag = 'ol' if ordered else 'ul'
            out.append(f'<{tag}>' + ''.join(f'<li>{inline(x)}</li>' for x in items) + f'</{tag}>'); continue
        if l.startswith('> '):
            flush(); buf = []
            while i < len(lines) and lines[i].startswith('>'): buf.append(lines[i][1:].strip()); i += 1
            out.append('<blockquote>' + inline(' '.join(buf)) + '</blockquote>'); continue
        if not l.strip(): flush(); i += 1; continue
        para.append(l.strip()); i += 1
    flush()
    return '\n'.join(out)


def front(text):
    meta, body = {}, text
    if text.startswith('---\n'):
        end = text.find('\n---', 4)
        for l in text[4:end].split('\n'):
            if ':' in l:
                k, v = l.split(':', 1); meta[k.strip()] = v.strip()
        body = text[end + 4:].lstrip('\n')
    return meta, body

# ───────────────────────── dartdoc → parameter tables ─────────────────────────
_src_cache = {}

def _sources():
    if not _src_cache:
        for f in glob.glob(os.path.join(LIB, 'src', '**', '*.dart'), recursive=True):
            _src_cache[f] = open(f, encoding='utf8').read()
    return _src_cache


def _split_top(s):
    parts, depth, cur, q = [], 0, '', None
    for ch in s:
        if q:
            cur += ch
            if ch == q: q = None
            continue
        if ch in '\'"': q = ch; cur += ch; continue
        if ch in '([{<': depth += 1
        if ch in ')]}>': depth -= 1
        if ch == ',' and depth == 0: parts.append(cur.strip()); cur = ''
        else: cur += ch
    if cur.strip(): parts.append(cur.strip())
    return parts


def _clean_doc(d):
    d = re.sub(r'\[([^\]]+)\]', r'`\1`', d)
    d = re.sub(r'```.*?```', '', d)
    d = d.replace('|', '\\|')
    first = re.split(r'(?<=[.!?])\s', d, maxsplit=2)
    out = ' '.join(first[:2]).strip()
    if len(out) > 260: out = out[:260].rsplit(' ', 1)[0] + '…'
    return out


def api_table(cls):
    """Returns (class doc, rows[name,type,default,doc]) of a class, or None."""
    for f, s in _sources().items():
        m = re.search(r'^(?:abstract |final |sealed )*class ' + cls + r'\b[^{]*\{', s, re.M)
        if not m: continue
        end = s.find('\n}\n', m.end()); body = s[m.end():end if end > 0 else len(s)]
        # fields and docs
        fields, doc = {}, []
        for l in body.split('\n'):
            t = l.strip()
            if t.startswith('///'): doc.append(t[3:].strip()); continue
            mm = re.match(r'(?:late )?final ([\w<>?,\s\(\)\.]+?) (\w+)(?:;| =)', t)
            if mm: fields[mm.group(2)] = (mm.group(1).strip(), ' '.join(doc))
            if not t.startswith('@'): doc = []
        cm = re.search(r'(?:const )?' + cls + r'(?:\.\w+)?\(\s*\{(.*?)\}\s*\)', body, re.S)
        rows = []
        if cm:
            for p in _split_top(re.sub(r'//[^\n]*', '', cm.group(1))):
                req = p.startswith('required ')
                p = p.replace('required ', '')
                dm = re.match(r'(this\.|super\.)?(?:([\w<>?,\s\(\)\.]+?)\s+)?(\w+)(?:\s*=\s*(.*))?$', p, re.S)
                if not dm: continue
                name, default = dm.group(3), (dm.group(4) or '').strip()
                if name == 'key': continue
                typ, d = fields.get(name, (dm.group(2) or '', ''))
                rows.append([name, typ.replace('|', '\\|'), 'required' if req and not default else default.replace('|', '\\|'), _clean_doc(d)])
        pre = s[:m.start()].rstrip('\n').split('\n'); cd = []
        for l in reversed(pre):
            if l.startswith('///'): cd.insert(0, l[3:].strip())
            elif l.startswith('@'): continue
            else: break
        return ' '.join(cd), rows
    return None


def exported_classes():
    """Public classes / show* functions of the kit and the files exporting them."""
    names = set()
    for f, s in _sources().items():
        for m in re.finditer(r'^(?:abstract |final |sealed |base )*class ([A-Z]\w*)|^Future<[^>]*> (show\w+)\(', s, re.M):
            names.add(m.group(1) or m.group(2))
    return names

# ───────────────────────── templates ─────────────────────────
def asset_variants(name):
    d = os.path.join(ASSETS, 'img')
    res = {}
    for theme in ('dark', 'light'):
        for ext in ('png', 'jpg', 'webp'):
            if os.path.exists(os.path.join(d, f'{name}-{theme}.{ext}')): res[theme] = f'{name}-{theme}.{ext}'
    for ext in ('png', 'jpg', 'webp', 'gif'):
        if os.path.exists(os.path.join(d, f'{name}.{ext}')): res['any'] = f'{name}.{ext}'
    return res


def gallery(meta, root):
    figs = []
    for spec in [x for x in meta.get('images', '').split(',') if x.strip()]:
        name, _, cap = spec.strip().partition('|')
        v = asset_variants(name.strip())
        if not v: continue
        imgs = ''
        if 'any' in v and not ('dark' in v or 'light' in v):
            imgs = f'<img src="{root}assets/img/{v["any"]}" alt="{esc(cap or name)}" loading="lazy">'
        else:
            dk = v.get('dark') or v.get('light'); lt = v.get('light') or v.get('dark')
            imgs = (f'<img class="shot-dark" src="{root}assets/img/{dk}" alt="{esc(cap or name)}" loading="lazy">'
                    f'<img class="shot-light" src="{root}assets/img/{lt}" alt="{esc(cap or name)}" loading="lazy">')
        figs.append(f'<figure>{imgs}<figcaption>{esc(cap)}</figcaption></figure>')
    for spec in [x for x in meta.get('videos', '').split(',') if x.strip()]:
        name, _, cap = spec.strip().partition('|')
        name = name.strip()
        if not os.path.exists(os.path.join(ASSETS, 'img', f'{name}.mp4')): continue
        poster = f' poster="{root}assets/img/{name}.jpg"' if os.path.exists(os.path.join(ASSETS, 'img', f'{name}.jpg')) else ''
        figs.append(f'<figure><video src="{root}assets/img/{name}.mp4"{poster} autoplay loop muted playsinline controls></video><figcaption>{esc(cap)}</figcaption></figure>')
    return '<div class="gallery">' + ''.join(figs) + '</div>' if figs else ''


def first_image(meta, root):
    for spec in [x for x in meta.get('images', '').split(',') if x.strip()]:
        name = spec.strip().partition('|')[0].strip()
        v = asset_variants(name)
        if v: return f'{root}assets/img/' + (v.get('dark') or v.get('light') or v['any'])
    return None


PAGE = '''<!doctype html>
<html lang="ru" data-theme="auto">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} · swiftuikit</title>
<script>try{{var t=localStorage.getItem('docs-theme');if(t)document.documentElement.dataset.theme=t}}catch(e){{}}</script>
<link rel="stylesheet" href="{root}assets/style.css">
</head>
<body>
<header class="top">
  <button class="menu" id="menu" aria-label="Меню">☰</button>
  <a class="brand" href="{root}index.html"><span class="logo">◐</span> swiftuikit</a>
  <div class="search"><input id="q" type="search" placeholder="Поиск виджетов  ( / )" autocomplete="off"><div id="results" hidden></div></div>
  <button class="themebtn" id="theme" aria-label="Тема сайта" title="Тема сайта">◐</button>
</header>
<div class="layout">
<nav class="side" id="side">{nav}</nav>
<main>{body}</main>
</div>
<script>window.DOCS_ROOT="{root}";</script>
<script src="{root}assets/search-index.js"></script>
<script src="{root}assets/app.js"></script>
</body>
</html>
'''


def build():
    nav_cfg = json.load(open(os.path.join(CONTENT, 'nav.json'), encoding='utf8'))
    guides, widgets = [], []
    for f in sorted(glob.glob(os.path.join(CONTENT, 'guides', '*.md'))):
        m, b = front(open(f, encoding='utf8').read()); m['slug'] = os.path.basename(f)[:-3]; m['body'] = b; guides.append(m)
    for f in sorted(glob.glob(os.path.join(CONTENT, 'widgets', '*.md'))):
        m, b = front(open(f, encoding='utf8').read()); m['slug'] = os.path.basename(f)[:-3]; m['body'] = b; widgets.append(m)
    guides.sort(key=lambda g: int(g.get('order', 99)))
    index_md = front(open(os.path.join(CONTENT, 'index.md'), encoding='utf8').read())
    groups = nav_cfg['widget_groups']
    for w in widgets:
        if w.get('group') not in groups: print('! unknown group', w['slug'], w.get('group'))
    widgets.sort(key=lambda w: (groups.index(w['group']) if w.get('group') in groups else 99, int(w.get('order', 50)), w['title'].lower()))

    def nav_html(root, cur):
        h = [f'<a class="navlink{" on" if cur == "index" else ""}" href="{root}index.html">Главная</a>', '<div class="navhead">Гайды</div>']
        for g in guides:
            h.append(f'<a class="navlink{" on" if cur == "guides/" + g["slug"] else ""}" href="{root}guides/{g["slug"]}.html">{esc(g["title"])}</a>')
        h.append(f'<div class="navhead"><a href="{root}widgets/index.html">Каталог виджетов</a></div>')
        for grp in groups:
            items = [w for w in widgets if w.get('group') == grp]
            if not items: continue
            h.append(f'<div class="navgroup">{esc(grp)}</div>')
            for w in items:
                h.append(f'<a class="navlink sub{" on" if cur == "widgets/" + w["slug"] else ""}" href="{root}widgets/{w["slug"]}.html">{esc(w["title"])}</a>')
        h.append(f'<div class="navhead"><a href="{root}coverage.html">Покрытие</a></div>')
        return '\n'.join(h)

    def write(rel, title, body, cur):
        root = '../' * rel.count('/')
        p = os.path.join(DIST, rel); os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, 'w', encoding='utf8').write(PAGE.format(title=esc(title), root=root, nav=nav_html(root, cur), body=body))

    if os.path.exists(DIST): shutil.rmtree(DIST)
    os.makedirs(DIST)
    shutil.copytree(ASSETS, os.path.join(DIST, 'assets'))
    # unused heavy sources are not needed in dist
    covered, search = set(), []

    # widget pages
    for w in widgets:
        root = '../'
        apis = [a.strip() for a in w.get('api', '').split(',') if a.strip()]
        covered.update(apis)
        parts = [f'<div class="crumb"><a href="{root}widgets/index.html">Каталог</a> / {esc(w.get("group", ""))}</div>',
                 f'<h1>{esc(w["title"])}</h1>', f'<p class="lead">{inline(w.get("summary", ""))}</p>']
        g = gallery(w, root)
        if g: parts.append('<h2 id="vid">Как выглядит</h2>' + g)
        parts.append(md(w['body']))
        tabs = []
        for a in apis:
            t = api_table(a)
            if not t: continue
            doc, rows = t
            if not rows: continue
            tabs.append(f'<details{" open" if not tabs else ""}><summary><code>{esc(a)}</code></summary>'
                        + md('| Параметр | Тип | По умолчанию | Описание |\n|---|---|---|---|\n' + '\n'.join('| `%s` | `%s` | %s | %s |' % (r[0], r[1] or '—', ('`%s`' % r[2]) if r[2] else '', r[3]) for r in rows))
                        + '</details>')
        if tabs: parts.append('<h2 id="parametry">Параметры <small>(из dartdoc)</small></h2>' + ''.join(tabs))
        parts.append(f'<p class="imp">Импорт: <code>import \'package:swiftuikit/swiftuikit.dart\';</code></p>')
        write(f'widgets/{w["slug"]}.html', w['title'], '<article>' + '\n'.join(parts) + '</article>', 'widgets/' + w['slug'])
        search.append({'t': w['title'], 'u': f'widgets/{w["slug"]}.html', 'g': w.get('group', ''), 's': w.get('summary', ''), 'k': w.get('keywords', '') + ' ' + ' '.join(apis)})

    # catalog
    cat = ['<article><h1>Каталог виджетов</h1><p class="lead">Все публичные виджеты кита по группам. Внешний вид — реальные снимки с iOS-симулятора.</p>']
    for grp in groups:
        items = [w for w in widgets if w.get('group') == grp]
        if not items: continue
        cat.append(f'<h2>{esc(grp)}</h2><div class="cards">')
        for w in items:
            im = first_image(w, '')
            th = f'<div class="thumb"><img src="{im}" alt="" loading="lazy"></div>' if im else '<div class="thumb empty">◐</div>'
            cat.append(f'<a class="card" href="{w["slug"]}.html">{th}<div class="ct"><b>{esc(w["title"])}</b><span>{inline(w.get("summary", ""))}</span></div></a>')
        cat.append('</div>')
    cat.append('</article>')
    write('widgets/index.html', 'Каталог виджетов', '\n'.join(cat), 'widgets')

    # guides
    for gd in guides:
        g = gallery(gd, '../')
        write(f'guides/{gd["slug"]}.html', gd['title'],
              f'<article><h1>{esc(gd["title"])}</h1><p class="lead">{inline(gd.get("summary", ""))}</p>' + g + md(gd['body']) + '</article>', 'guides/' + gd['slug'])
        search.append({'t': gd['title'], 'u': f'guides/{gd["slug"]}.html', 'g': 'Гайды', 's': gd.get('summary', ''), 'k': gd.get('keywords', '')})

    # home
    im = index_md[0]
    hero = gallery(im, '')
    hp = [f'<article class="home"><h1>{esc(im.get("title", "swiftuikit"))}</h1><p class="lead">{inline(im.get("summary", ""))}</p>', hero, md(index_md[1])]
    hp.append('<h2>Гайды</h2><div class="cards">' + ''.join(f'<a class="card" href="guides/{g["slug"]}.html"><div class="ct"><b>{esc(g["title"])}</b><span>{inline(g.get("summary", ""))}</span></div></a>' for g in guides) + '</div>')
    hp.append('<h2>Каталог</h2><div class="cards">' + ''.join(
        f'<a class="card" href="widgets/index.html#{re.sub(r"[^a-z0-9]+", "-", grp.lower())}"><div class="ct"><b>{esc(grp)}</b><span>{", ".join(esc(w["title"]) for w in widgets if w.get("group") == grp)}</span></div></a>' for grp in groups) + '</div></article>')
    write('index.html', 'swiftuikit', '\n'.join(hp), 'index')

    # coverage
    allc = sorted(n for n in exported_classes() if not n.startswith('_'))
    ignore = set(nav_cfg.get('internal', []))
    missing = [n for n in allc if n not in covered and n not in ignore]
    cov = ['<article><h1>Покрытие документацией</h1>',
           f'<p class="lead">Страниц виджетов: {len(widgets)}, гайдов: {len(guides)}. Публичных классов и функций <code>show*</code> в <code>lib/src</code>: {len(allc)}; описано (поле <code>api</code>): {len([n for n in allc if n in covered])}; внутренние/служебные (список <code>internal</code> в <code>nav.json</code>): {len((ignore & set(allc)) - covered)}.</p>',
           '<h2>Не описано</h2>', ('<ul>' + ''.join(f'<li><code>{esc(n)}</code></li>' for n in missing) + '</ul>') if missing else '<p>Ничего: каждый публичный класс либо описан, либо помечен внутренним.</p>',
           '<h2>Без снимков</h2><ul>' + ''.join(f'<li><a href="widgets/{w["slug"]}.html">{esc(w["title"])}</a></li>' for w in widgets if not first_image(w, '') and not w.get('videos')) + '</ul></article>']
    write('coverage.html', 'Покрытие', '\n'.join(cov), 'coverage')
    open(os.path.join(DIST, 'assets', 'search-index.js'), 'w', encoding='utf8').write('window.DOCS_INDEX=' + json.dumps(search, ensure_ascii=False) + ';')
    print(f'built: {len(widgets)} widgets, {len(guides)} guides -> {DIST}')
    if missing: print('not documented:', ', '.join(missing))


if __name__ == '__main__':
    build()
    if '--serve' in sys.argv:
        import http.server, functools
        os.chdir(DIST)
        print('http://localhost:8000')
        http.server.test(HandlerClass=http.server.SimpleHTTPRequestHandler, port=8000)
