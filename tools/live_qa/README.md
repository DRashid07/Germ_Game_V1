# Canlı QA aləti — oyunu addım-addım "əl ilə" oynamaq

2026-11-22-də oyunu canlı yoxlamaq üçün yazılıb (hesabat: [docs/QA_HESABAT_2026-11-22.md](../../docs/QA_HESABAT_2026-11-22.md)).
Oyunun özünə daxil DEYİL — yalnız scratch nüsxədə autoload kimi qoşulur.

## Qurulum (scratch nüsxə, sahibin ayarlarına toxunmur)

1. `game/` qovluğunu müvəqqəti yerə kopyala.
2. Nüsxənin `project.godot`-unda `[application]` altına:
   `config/use_custom_user_dir=true` və `config/custom_user_dir_name="GermArenaLiveQA"`.
3. `[autoload]` altına: `LiveQA="*res://scripts/tools/live_driver.gd"`, faylı da ora kopyala.
4. Aç: `Godot_v4.7.2-stable_win64_console.exe --path <nüsxə> --resolution 1280x720 -- --live 7777 --live-out C:/yol/shots`

`--live` olmadan autoload dərhal silinir.

## İstifadə

```
node brief.js '{"cmd":"state"}'                          # səhnə, öz mikrob, rəqiblər, HUD yazıları
node brief.js '{"cmd":"ui"}'                             # görünən düymələr və yazılar (koordinatla)
node brief.js '{"cmd":"click","text":"MƏŞQ","wait":2}'   # düyməyə mətnlə və ya {"x","y"} ilə bas
node brief.js '{"cmd":"run","secs":5,"toward":"enemy","keep":350,"fire":"auto","shot_every":1}'
node brief.js '{"cmd":"key","key":"ESC"}'
node brief.js '{"cmd":"shot","name":"kadr","scale":0.6}'
node brief.js '{"cmd":"eval","expr":"arena._obj"}'       # arena / menu / tree dəyişənləri
```

- Arenada **addım rejimi** standartdır: əmrlər arasında oyun donur (`get_tree().paused`),
  yəni yavaş düşünən oyunçu da real vaxt itirmir. Onlayn oynayanda `{"cmd":"step","on":false}`.
- `run` parametrləri: `move:[x,y]`, `toward:[x,y]|"food"|"enemy"|"center"`, `keep`, `orbit`, `flee`,
  `fire:"tap"|"aim"|"auto"`, `aim:[x,y]`, `power`, `fire_every`, `range`, `reserve`, `super`,
  `super_hold`, `membrane_at`, `keys:[...]`, `shot_every`, `finish_shots`, `release`.
- Cavabdakı `log` top sayı, tutum, faza, HUD yazılarının dəyişməsi, partlayış, zərbə və
  `OWN_DEAD` keçidlərini zamanla yazır.
- Giriş həqiqi toxunuş/siçan/klaviatura hadisələridir (`push_input` / `Input.parse_input_event`) —
  joystik, atəş, super və membran düymələri oyunçunun yolundan keçir.
