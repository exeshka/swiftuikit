# HDR / EDR для жидкого стекла: что проверено

Нативное свечение `.interactive()` ярче SDR-белого (EDR). Проверка, можно ли это получить во Flutter.

## iOS (проверено на iPhone 14 Pro, iOS 27, release-сборка)
- Симулятор не годится: wide gamut там не поддерживается (`isWideGamutSupported`), скриншоты SDR.
- С ключом `FLTEnableWideGamut = YES` в Info.plist слой Flutter — `FlutterMetalLayer`, `pixelFormat = 552`
  (`MTLPixelFormatBGR10_XR`), цветовое пространство `kCGColorSpaceExtendedSRGB`. Диапазон формата XR: −0.75…1.25,
  то есть **максимум 1.25 от SDR-белого**, а нативная подсветка ярче.
- В движке (Flutter.framework 3.47) нет `wantsExtendedDynamicRangeContent`: сам он EDR не включает. Флаг можно выставить
  нативным кодом на слое и подслоях (iOS 17+): принимается (`edr=true`), после этого система поднимает headroom экрана
  с 1.2 до 8.0 (`UIScreen.currentEDRHeadroom`, лог с устройства). Значит, система считает контент EDR.
- Что реально видно глазом (значения 1.25 / 2.0 против 1.0), смотрит человек: экран «EDR test» в демо
  (`--dart-define=SCREEN=edr-test`) рисует квадраты 1.0 / 1.25 / 2.0 в `ColorSpace.extendedSRGB` и каждые 8 с
  переключает флаг.
- Результат глазами на iPhone 14 Pro: квадрат 1.0 серый, 1.25 заметно белее, 2.0 выглядит как 1.25 (потолок формата).
  То есть расширенный диапазон работает, но только до 1.25.
- В стекле: токен `liquidHdr` (по умолчанию 1.0 = только SDR) задаёт пик подсветки нажатия и каёмки; при 1.25 они
  смешиваются не с белым, а с 1.25. Нужно приложению: `FLTEnableWideGamut` в Info.plist и нативный флаг EDR на слое
  (канал `ravel/edr`, пример в демо; `--dart-define=HDR=true` на экране «Liquid glass interactive»).
- Чтобы выйти за 1.25 нужен float16-таргет (`RGBA16Float`) и расширенное линейное цветовое пространство: Impeller этого
  сейчас не умеет, это правка движка.

## macOS
- На слое Flutter обычный `CALayer` (IOSurface), у него `wantsExtendedDynamicRangeContent` (macOS 14+) выставляется
  нативным кодом (см. `example/macos/Runner/MainFlutterWindow.swift`); формат тоже BGR10_XR, потолок 1.25.
- `NSScreen.maximumExtendedDynamicRangeColorComponentValue` на этом MacBook Air M1 уже 2.0 без нашего приложения
  (что-то ещё держит HDR), поэтому по headroom влияние флага измерить не удалось.

## Android, Windows, web (по документации, не проверялось)
- Android: окну нужен `COLOR_MODE_HDR` (или wide color), Vulkan-свопчейн `R16G16B16A16_SFLOAT` +
  `EXTENDED_SRGB_LINEAR`; Impeller-Vulkan сам это не выбирает (не нашёл подтверждения обратного).
- Windows: HDR-вывод через DXGI `R16G16B16A16_FLOAT` + `G22_NONE_P709`/scRGB; в Flutter-движке не включён.
- Web: HDR-canvas (`pixelFormat: 'float16'`, Chrome) и CSS `dynamic-range-limit` (Chrome/Edge 136+, Safari 26+);
  CanvasKit/Skwasm этого не используют.
- Общее решение для всех платформ: не шейдером, а нативным слоем поверх (отдельный HDR-слой с блик-градиентом
  через platform view / texture), либо правка движка под float16-таргет.

## Файлы эксперимента
`example/lib/screens/edr_test_screen.dart`, канал `ravel/edr` в `example/ios/Runner/AppDelegate.swift` и
`example/macos/Runner/MainFlutterWindow.swift`; лог устройства пишется в `Documents/edr_log.txt`.
