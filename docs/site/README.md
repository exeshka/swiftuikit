# Сайт документации swiftuikit

Статический сайт: гайды и каталог виджетов с описанием, кодом, таблицей параметров (из dartdoc) и снимками реального рендера (iOS-симулятор, тёмная и светлая темы). Шейдеры стекла не работают на Flutter Web, поэтому картинки — снимки и видео, а не live-демо.

## Посмотреть

Собранный сайт лежит в `dist/` и открывается двойным кликом по `dist/index.html` либо:

```bash
cd docs/site/dist && python3 -m http.server 8000   # http://localhost:8000
```

## Пересобрать

Нужен только Python 3 (без зависимостей).

```bash
python3 docs/site/build.py            # → docs/site/dist/
python3 docs/site/build.py --serve    # то же + сервер на :8000
```

Сборка читает `content/`, `assets/` и dartdoc из `lib/src/**`, выводит в консоль список публичных классов без описания и пишет страницу `dist/coverage.html`.

## Как добавить виджет

1. Создайте `content/widgets/<slug>.md`:

   ```markdown
   ---
   title: GlassFoo
   group: Формы и контролы          # одна из widget_groups в content/nav.json
   order: 10                        # порядок внутри группы (необязательно)
   summary: Одна строка: что это.
   api: GlassFoo,GlassFooItem       # классы, чьи параметры подтянутся из dartdoc
   images: foo|Подпись, foo-2|Вторая
   videos: foo-anim|Анимация        # assets/img/foo-anim.mp4 (необязательно)
   keywords: foo ключевые слова для поиска
   ---
   ## Что это
   Текст в markdown: заголовки, списки, таблицы, `код`, блоки ```dart.
   ```

2. Положите картинки в `assets/img/`: `foo-dark.jpg` + `foo-light.jpg` (сайт покажет вариант под свою тему) или один `foo.png`.
3. `python3 docs/site/build.py`. Страница появится в навигации, каталоге и поиске.

Гайды — `content/guides/NN-name.md` (поля `title`, `order`, `summary`, `images`, `videos`). Главная — `content/index.md`.

## Снимки

Экран примера (`example_ui_kit`) выбирается без пересборки: `tools/capture.sh` кладёт `launch.txt` (`SCREEN=…`, `THEME=…`) во временный каталог контейнера приложения, пример читает его через `launchOption` (`example_ui_kit/lib/app_state.dart`).

```bash
cd example_ui_kit && flutter build ios --simulator --debug && cd ..
docs/site/tools/capture.sh <udid симулятора> buttons:buttons sheets:sheets   # экран:имя файла
docs/site/tools/record.sh <udid> morph-menu 8                                # видео N секунд
```

Имена экранов — пути роутера примера (`example_ui_kit/lib/router/app_router.dart`): `buttons`, `sheets`, `controls`, `input`, `switch`, `nav-bars`, `liquid`, `sticky`, `telegram`…

## Устройство

| Файл | Что |
|---|---|
| `build.py` | генератор: markdown → HTML, подсветка кода, таблицы параметров, поиск, покрытие |
| `content/nav.json` | порядок групп каталога, список служебных классов (не требуют описания) |
| `assets/style.css`, `assets/app.js` | оформление, тема сайта, поиск, копирование кода |
| `tools/capture.sh` | снимки экранов с симулятора |

## Покрытие

См. `dist/coverage.html` (генерируется) и раздел «Покрытие» в итоговом отчёте. Известные пробелы: нет снимков отдельных состояний (нажатие, перетаскивание) — их показывают видео; для служебных/нестабильных классов (`SwiftScrollSheet*`, `SwiftModal*`) только краткое описание в странице «Маршруты и переходы».
