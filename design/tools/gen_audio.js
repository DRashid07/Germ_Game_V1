#!/usr/bin/env node

'use strict';

const fs = require('fs');
const path = require('path');

// Bütün səslər eyni mobil-oyun formatında yaradılır.
const SAMPLE_RATE = 44100;
const CHANNELS = 1;
const BITS_PER_SAMPLE = 16;
const TWO_PI = Math.PI * 2;
const OUTPUT_DIR = path.resolve(__dirname, '..', 'audio');

// Müddət hədləri saniyə ilə verilir; top atma səsi qəti şəkildə 0.13-dən qısadır,
// çünki fasiləsiz atəşdə (saniyədə ~3 top) uzun səs bir-birinə qarışır.
const SOUND_SPECS = [
  { file: 'eject.wav', duration: 0.105, limit: 0.130, strictLimit: true, peakDb: -6.5, create: createEject },
  { file: 'blunk.wav', duration: 0.115, limit: 0.140, strictLimit: true, peakDb: -7.0, create: createBlunk },
  { file: 'absorb.wav', duration: 0.090, limit: 0.110, peakDb: -8.0, create: createAbsorb },
  { file: 'hit.wav', duration: 0.145, limit: 0.170, peakDb: -4.5, create: createHit },
  { file: 'hit_confirm.wav', duration: 0.080, limit: 0.100, strictLimit: true, peakDb: -7.0, create: createHitConfirm },
  { file: 'burst.wav', duration: 0.700, limit: 0.780, peakDb: -1.5, create: createBurst },
  { file: 'spawn.wav', duration: 0.420, limit: 0.470, peakDb: -4.0, create: createSpawn },
  { file: 'danger.wav', duration: 0.240, limit: 0.280, peakDb: -5.0, create: createDanger },
  { file: 'level_up.wav', duration: 0.480, limit: 0.540, peakDb: -3.0, create: createLevelUp },
  { file: 'you_burst.wav', duration: 1.180, limit: 1.300, peakDb: -2.0, create: createYouBurst },
  { file: 'ui_click.wav', duration: 0.055, limit: 0.070, peakDb: -8.0, create: createUiClick },
];

function secondsToFrames(seconds) {
  return Math.round(seconds * SAMPLE_RATE);
}

function blankSound(duration) {
  return new Float64Array(secondsToFrames(duration));
}

function dbToGain(db) {
  return 10 ** (db / 20);
}

function clamp(value, low, high) {
  return Math.max(low, Math.min(high, value));
}

// Kosinus rampası sərt zərf künclərini yumşaldır.
function smoothStep01(value) {
  const x = clamp(value, 0, 1);
  return 0.5 - 0.5 * Math.cos(Math.PI * x);
}

// Hər çağırış ayrıca toxum alır; nəticə hər generasiyada bit-dəqiq təkrarlanır.
function makePrng(seed) {
  let state = seed >>> 0;
  if (state === 0) state = 0x6d2b79f5;
  return () => {
    state ^= state << 13;
    state ^= state >>> 17;
    state ^= state << 5;
    return (state >>> 0) / 0x100000000;
  };
}

function oscillatorValue(phase, waveform, harmonics) {
  if (waveform === 'triangle') {
    return (2 / Math.PI) * Math.asin(Math.sin(phase));
  }

  let value = 0;
  let weight = 0;
  for (const [multiple, level] of harmonics) {
    value += Math.sin(phase * multiple) * level;
    weight += Math.abs(level);
  }
  return weight > 0 ? value / weight : 0;
}

// Ton qatı sabit notu da, eksponensial tezlik sürüşməsini də yarada bilir.
function addTone(samples, options) {
  const {
    start = 0,
    duration,
    frequencyStart,
    frequencyEnd = frequencyStart,
    amplitude,
    attack = 0.003,
    release = 0.020,
    decayTime = Infinity,
    glideCurve = 1,
    waveform = 'sine',
    harmonics = [[1, 1]],
    phaseOffset = 0,
  } = options;

  const startFrame = Math.max(0, secondsToFrames(start));
  const frameCount = Math.max(1, secondsToFrames(duration));
  const endFrame = Math.min(samples.length, startFrame + frameCount);
  let phase = phaseOffset;

  for (let frame = startFrame; frame < endFrame; frame += 1) {
    const localFrame = frame - startFrame;
    const localTime = localFrame / SAMPLE_RATE;
    const progress = frameCount > 1 ? localFrame / (frameCount - 1) : 1;
    const curvedProgress = progress ** glideCurve;
    const frequency = frequencyStart * ((frequencyEnd / frequencyStart) ** curvedProgress);

    phase += TWO_PI * frequency / SAMPLE_RATE;

    const attackGain = attack > 0 ? smoothStep01(localTime / attack) : 1;
    const remaining = Math.max(0, duration - localTime);
    const releaseGain = release > 0 ? smoothStep01(remaining / release) : 1;
    const decayGain = Number.isFinite(decayTime) ? Math.exp(-localTime / decayTime) : 1;
    const envelope = amplitude * attackGain * releaseGain * decayGain;

    samples[frame] += oscillatorValue(phase, waveform, harmonics) * envelope;
  }
}

// İki birqütblü filtr səs-küyü seçilmiş tezlik zolağında saxlayır.
function addFilteredNoise(samples, options) {
  const {
    start = 0,
    duration,
    amplitude,
    lowCut = 0,
    highCut = 10000,
    attack = 0.001,
    release = 0.012,
    decayTime = Infinity,
    seed = 1,
  } = options;

  const random = makePrng(seed);
  const startFrame = Math.max(0, secondsToFrames(start));
  const frameCount = Math.max(1, secondsToFrames(duration));
  const endFrame = Math.min(samples.length, startFrame + frameCount);
  const highAlpha = 1 - Math.exp(-TWO_PI * Math.min(highCut, SAMPLE_RATE * 0.45) / SAMPLE_RATE);
  const lowAlpha = lowCut > 0 ? 1 - Math.exp(-TWO_PI * lowCut / SAMPLE_RATE) : 0;
  let highState = 0;
  let lowState = 0;

  for (let frame = startFrame; frame < endFrame; frame += 1) {
    const localFrame = frame - startFrame;
    const localTime = localFrame / SAMPLE_RATE;
    const white = random() * 2 - 1;

    highState += highAlpha * (white - highState);
    if (lowCut > 0) lowState += lowAlpha * (highState - lowState);
    const filtered = lowCut > 0 ? highState - lowState : highState;

    const attackGain = attack > 0 ? smoothStep01(localTime / attack) : 1;
    const remaining = Math.max(0, duration - localTime);
    const releaseGain = release > 0 ? smoothStep01(remaining / release) : 1;
    const decayGain = Number.isFinite(decayTime) ? Math.exp(-localTime / decayTime) : 1;

    samples[frame] += filtered * amplitude * attackGain * releaseGain * decayGain;
  }
}

function removeDc(samples) {
  let sum = 0;
  for (const sample of samples) sum += sample;
  const mean = sum / samples.length;
  for (let i = 0; i < samples.length; i += 1) samples[i] -= mean;
}

// Qısa ümumi fade bütün kliplərdə başlanğıc və son kliklərini aradan qaldırır.
function applyEdgeFades(samples, fadeInSeconds, fadeOutSeconds) {
  const fadeInFrames = Math.min(samples.length, Math.max(2, secondsToFrames(fadeInSeconds)));
  const fadeOutFrames = Math.min(samples.length, Math.max(2, secondsToFrames(fadeOutSeconds)));

  for (let i = 0; i < fadeInFrames; i += 1) {
    samples[i] *= smoothStep01(i / (fadeInFrames - 1));
  }
  for (let i = 0; i < fadeOutFrames; i += 1) {
    const frame = samples.length - 1 - i;
    samples[frame] *= smoothStep01(i / (fadeOutFrames - 1));
  }
}

// Yüngül yumşaq doyma qatları birləşdirir, sonra pik hədəfi təhlükəsiz səviyyəyə gətirilir.
function finishSound(samples, peakDb, options = {}) {
  const { drive = 1.0, fadeIn = 0.003, fadeOut = 0.006 } = options;
  removeDc(samples);

  if (drive > 1) {
    const scale = Math.tanh(drive);
    for (let i = 0; i < samples.length; i += 1) {
      samples[i] = Math.tanh(samples[i] * drive) / scale;
    }
  }

  applyEdgeFades(samples, fadeIn, fadeOut);

  let peak = 0;
  for (const sample of samples) peak = Math.max(peak, Math.abs(sample));
  if (peak === 0) throw new Error('Səssiz nümunə yaradıldı.');

  const scale = dbToGain(peakDb) / peak;
  for (let i = 0; i < samples.length; i += 1) samples[i] *= scale;
  return samples;
}

// ── Səslərin dili ───────────────────────────────────────────────────────────
// Bütün oyun MAYE dünyasıdır: heç bir səs "metal" olmamalıdır. Ona görə
// zərbə səsləri deyil, YAŞ səslər işlədilir — qabarcıq, çırtıltı, sıçrama.
// Ayrıntılar: design/AUDIO_BIBLE.md

// Top atma — mikrobun membranından bir topun çıxması. Qısa "püf".
function createEject(spec) {
  const sound = blankSound(spec.duration);

  addFilteredNoise(sound, {
    duration: 0.055,
    amplitude: 0.55,
    lowCut: 260,
    highCut: 2600,
    decayTime: 0.016,
    seed: 0x51ea,
  });

  // Enən ton = təzyiqin boşalması.
  addTone(sound, {
    duration: 0.090,
    frequencyStart: 460,
    frequencyEnd: 175,
    amplitude: 0.45,
    decayTime: 0.030,
    glideCurve: 0.55,
    waveform: 'triangle',
  });

  return finishSound(sound, spec.peakDb, { drive: 1.15 });
}

// Topun membranı YARIB çıxdığı an — "blunk".
//
// `eject` təzyiqin özüdür və atəş anında səslənir; bu isə ondan bir qədər
// SONRA, top divardan keçəndə çıxır (gecikmə radius / SHOT_SPEED — böyük
// mikrobda 200 ms-ə çatır). İkisi birlikdə "sıxdı → çıxardı" cütü verir.
//
// Səsin özü qəsdən aşağıdır və tez enir: gərilmiş nazik pərdənin buraxılması
// belə səslənir. Metal yoxdur — yalnız yaş pərdə və içindəki maye.
function createBlunk(spec) {
  const sound = blankSound(spec.duration);

  // Pərdənin qopma çırtıltısı — çox qısa, yoxsa "cırılma" kimi eşidilir.
  addFilteredNoise(sound, {
    duration: 0.014,
    amplitude: 0.30,
    lowCut: 320,
    highCut: 1900,
    decayTime: 0.006,
    seed: 0xb10c,
  });

  // Əsas "blunk": sürətlə enən ton. Enmə kəskindir (`glideCurve` yüksək),
  // ona görə səs "bluu" yox, "blunk" oxunur.
  addTone(sound, {
    duration: 0.098,
    frequencyStart: 610,
    frequencyEnd: 112,
    amplitude: 0.62,
    attack: 0.003,
    decayTime: 0.042,
    glideCurve: 0.85,
    harmonics: [[1, 1], [2, 0.18]],
  });

  // Gövdənin içindəki mayenin cavabı — bir az uzun, çox sakit.
  addTone(sound, {
    duration: 0.085,
    frequencyStart: 168,
    frequencyEnd: 88,
    amplitude: 0.22,
    decayTime: 0.055,
    glideCurve: 0.5,
    waveform: 'sine',
  });

  return finishSound(sound, spec.peakDb, { drive: 1.08 });
}

// Qida udmaq — qalxan "blup". Oyunçu ekrana baxmadan yediyini bilməlidir.
function createAbsorb(spec) {
  const sound = blankSound(spec.duration);

  addTone(sound, {
    duration: 0.075,
    frequencyStart: 280,
    frequencyEnd: 880,
    amplitude: 0.60,
    attack: 0.004,
    decayTime: 0.045,
    glideCurve: 0.7,
    harmonics: [[1, 1], [2, 0.22]],
  });

  addFilteredNoise(sound, {
    duration: 0.022,
    amplitude: 0.18,
    lowCut: 600,
    highCut: 4200,
    decayTime: 0.008,
    seed: 0x0b10,
  });

  return finishSound(sound, spec.peakDb);
}

// Top rəqibin membranına keçdi — yaş, dolğun "çırt".
// Qəsdən `eject`-dən aşağı tezlik sahəsindədir: oyunçu atışının TUTDUĞUNU
// eşitməlidir, ekrana baxmasa belə.
function createHit(spec) {
  const sound = blankSound(spec.duration);

  addFilteredNoise(sound, {
    duration: 0.090,
    amplitude: 0.70,
    lowCut: 180,
    highCut: 3000,
    decayTime: 0.028,
    seed: 0x4177,
  });

  addTone(sound, {
    duration: 0.130,
    frequencyStart: 210,
    frequencyEnd: 82,
    amplitude: 0.75,
    decayTime: 0.048,
    glideCurve: 0.6,
    harmonics: [[1, 1], [2, 0.3], [3, 0.12]],
  });

  return finishSound(sound, spec.peakDb, { drive: 1.35 });
}

// SƏNİN atışın dəydi — hamıya çalan `hit`-in üstündə parlaq, qalxan qabarcıq.
// 900–2000 Hz gövdə onu aşağı `hit` və `eject`-dən ayırır; başlanğıcdakı qısa
// yüksək çırtıltı telefon dinamikində dərhal seçilir.
function createHitConfirm(spec) {
  const sound = blankSound(spec.duration);

  addFilteredNoise(sound, {
    duration: 0.012,
    amplitude: 0.38,
    lowCut: 3000,
    highCut: 6500,
    attack: 0.0004,
    release: 0.006,
    decayTime: 0.004,
    seed: 0xc0f1,
  });

  addTone(sound, {
    duration: 0.070,
    frequencyStart: 920,
    frequencyEnd: 1850,
    amplitude: 0.75,
    attack: 0.0012,
    release: 0.012,
    decayTime: 0.030,
    glideCurve: 0.65,
    harmonics: [[1, 1], [2, 0.16], [3, 0.04]],
  });

  return finishSound(sound, spec.peakDb, { fadeIn: 0.0015, fadeOut: 0.005 });
}

// Mikrob partladı — dünyanın ən vacib səsi və oyunun yeganə ÖLÜM səsi.
//
// Beş qat, hər biri ayrı bir zaman miqyasında. Səbəb budur: partlayış ekranda
// bir anlıq hadisədir, amma qulaq onu üç fazada oxuyur — nə oldu (transient),
// nə qədər böyük idi (sub), nədən ibarət idi (damcılar). Tək bir "boom"
// hadisəni bildirir, amma onun MAYE olduğunu demir; bu oyunda isə partlayan
// şey bir su kisəsidir (bax AUDIO_BIBLE §1 — heç bir səs metal deyil).
function createBurst(spec) {
  const sound = blankSound(spec.duration);

  // 1. Qopma anı — membranın cırıldığı ilk 8 ms. Çox qısadır, amma
  //    partlayışa "zərbə" hissini verən yeganə qatdır.
  addFilteredNoise(sound, {
    duration: 0.030,
    amplitude: 1.00,
    lowCut: 900,
    highCut: 9000,
    attack: 0.0006,
    decayTime: 0.006,
    seed: 0x1d77,
  });

  // 2. Membranın cırılması.
  addFilteredNoise(sound, {
    duration: 0.190,
    amplitude: 0.85,
    lowCut: 300,
    highCut: 5400,
    decayTime: 0.052,
    seed: 0x7b05,
  });

  // 3. Yayılan maye — yaş, dolğun gövdə.
  addFilteredNoise(sound, {
    start: 0.025,
    duration: 0.520,
    amplitude: 0.55,
    lowCut: 85,
    highCut: 1500,
    decayTime: 0.155,
    seed: 0x2c19,
  });

  // 4. Alt tezlik — partlayışın ağırlığı. Dünyada BAŞQA heç bir klip bura
  //    enmir, ona görə telefonun kiçik dinamikində belə seçilir.
  addTone(sound, {
    duration: 0.440,
    frequencyStart: 240,
    frequencyEnd: 34,
    amplitude: 0.95,
    decayTime: 0.165,
    glideCurve: 0.45,
    harmonics: [[1, 1], [2, 0.25]],
  });

  // 5. Damcı quyruğu — səpilən topların suya düşməsi. Üç qalxan qabarcıq,
  //    `absorb` ilə eyni dildə: partlayış həm ölümdür, həm də yerdə qalan
  //    qidadır, quyruq elə həmin təklifi səsləndirir.
  for (const [start, from, to, level] of [[0.180, 300, 700, 0.20],
                                          [0.270, 240, 560, 0.16],
                                          [0.380, 190, 430, 0.12]]) {
    addTone(sound, {
      start,
      duration: 0.090,
      frequencyStart: from,
      frequencyEnd: to,
      amplitude: level,
      attack: 0.005,
      decayTime: 0.040,
      glideCurve: 0.7,
      waveform: 'triangle',
    });
  }

  return finishSound(sound, spec.peakDb, { drive: 1.7 });
}

// Doğuş — üç qalxan qabarcıq. "Sən yenidən dünyadasan" mesajı.
function createSpawn(spec) {
  const sound = blankSound(spec.duration);
  const notes = [[0.000, 262, 392], [0.110, 349, 523], [0.230, 440, 660]];

  for (const [start, from, to] of notes) {
    addTone(sound, {
      start,
      duration: 0.150,
      frequencyStart: from,
      frequencyEnd: to,
      amplitude: 0.45,
      attack: 0.006,
      decayTime: 0.070,
      waveform: 'triangle',
    });
  }

  addFilteredNoise(sound, {
    duration: 0.060,
    amplitude: 0.16,
    lowCut: 400,
    highCut: 3600,
    decayTime: 0.022,
    seed: 0x9a31,
  });

  return finishSound(sound, spec.peakDb);
}

// Təhlükə — tutum dolmaq üzrədir və ya top sayı acdıq həddinə düşüb.
// İki eyni qısa siqnal: təkrarlanan ritm diqqəti tez çəkir.
function createDanger(spec) {
  const sound = blankSound(spec.duration);

  for (const start of [0.000, 0.130]) {
    addTone(sound, {
      start,
      duration: 0.085,
      frequencyStart: 740,
      frequencyEnd: 700,
      amplitude: 0.55,
      attack: 0.004,
      release: 0.018,
      harmonics: [[1, 1], [2, 0.35], [3, 0.14]],
    });
  }

  return finishSound(sound, spec.peakDb, { drive: 1.1 });
}

// Tutum artdı (rəqib partladıldı) — qalxan üç not, açıq-aydın mükafat səsi.
function createLevelUp(spec) {
  const sound = blankSound(spec.duration);
  const notes = [[0.000, 523], [0.105, 659], [0.210, 784]];

  for (const [start, frequency] of notes) {
    addTone(sound, {
      start,
      duration: 0.180,
      frequencyStart: frequency,
      amplitude: 0.42,
      attack: 0.005,
      decayTime: 0.090,
      harmonics: [[1, 1], [2, 0.28], [4, 0.08]],
    });
  }

  // Son not bir oktava yuxarıda təkrarlanır — "səviyyə qalxdı" hissi.
  addTone(sound, {
    start: 0.300,
    duration: 0.170,
    frequencyStart: 1046,
    amplitude: 0.34,
    attack: 0.006,
    decayTime: 0.075,
    waveform: 'triangle',
  });

  return finishSound(sound, spec.peakDb);
}

// SƏNİN mikrobun partladı — oyunun sonu.
//
// `burst` ilə eyni dildədir (eyni hadisə baş verir), amma üç fərqi var:
// daha aşağı enir (44 Hz əvəzinə 30), daha uzun sürür, və sonunda SÖNƏN
// NƏFƏS var. Qulaq ilk iki fərqi "böyük" kimi, üçüncüsünü isə "bitdi" kimi
// oxuyur — nəticə ekranı görünməmişdən əvvəl oyunçu artıq bilir.
function createYouBurst(spec) {
  const sound = blankSound(spec.duration);

  // Qopma anı.
  addFilteredNoise(sound, {
    duration: 0.035,
    amplitude: 1.00,
    lowCut: 800,
    highCut: 8600,
    attack: 0.0006,
    decayTime: 0.008,
    seed: 0x5ab1,
  });

  addFilteredNoise(sound, {
    duration: 0.240,
    amplitude: 0.82,
    lowCut: 250,
    highCut: 4800,
    decayTime: 0.072,
    seed: 0x3f52,
  });

  addTone(sound, {
    duration: 0.560,
    frequencyStart: 230,
    frequencyEnd: 30,
    amplitude: 0.90,
    decayTime: 0.200,
    glideCurve: 0.45,
    harmonics: [[1, 1], [2, 0.22]],
  });

  // Sönən nəfəs — məğlubiyyətin quyruğu.
  addTone(sound, {
    start: 0.320,
    duration: 0.720,
    frequencyStart: 392,
    frequencyEnd: 118,
    amplitude: 0.30,
    attack: 0.030,
    decayTime: 0.330,
    glideCurve: 0.8,
    waveform: 'triangle',
  });

  // Uzun maye quyruğu — dağılan sitoplazma.
  addFilteredNoise(sound, {
    start: 0.170,
    duration: 0.720,
    amplitude: 0.24,
    lowCut: 65,
    highCut: 950,
    decayTime: 0.250,
    seed: 0x6d84,
  });

  return finishSound(sound, spec.peakDb, { drive: 1.5 });
}

// Menyu toxunuşu — ən qısa klip, sadəcə təsdiq.
function createUiClick(spec) {
  const sound = blankSound(spec.duration);

  addTone(sound, {
    duration: 0.038,
    frequencyStart: 940,
    frequencyEnd: 620,
    amplitude: 0.50,
    attack: 0.002,
    decayTime: 0.014,
    waveform: 'triangle',
  });

  addFilteredNoise(sound, {
    duration: 0.020,
    amplitude: 0.20,
    lowCut: 900,
    highCut: 6000,
    decayTime: 0.006,
    seed: 0x1c0d,
  });

  return finishSound(sound, spec.peakDb);
}

function writeWav(filePath, samples) {
  const dataBytes = samples.length * 2;
  const wav = Buffer.alloc(44 + dataBytes);

  wav.write('RIFF', 0, 'ascii');
  wav.writeUInt32LE(36 + dataBytes, 4);
  wav.write('WAVE', 8, 'ascii');
  wav.write('fmt ', 12, 'ascii');
  wav.writeUInt32LE(16, 16);
  wav.writeUInt16LE(1, 20);
  wav.writeUInt16LE(CHANNELS, 22);
  wav.writeUInt32LE(SAMPLE_RATE, 24);
  wav.writeUInt32LE(SAMPLE_RATE * CHANNELS * (BITS_PER_SAMPLE / 8), 28);
  wav.writeUInt16LE(CHANNELS * (BITS_PER_SAMPLE / 8), 32);
  wav.writeUInt16LE(BITS_PER_SAMPLE, 34);
  wav.write('data', 36, 'ascii');
  wav.writeUInt32LE(dataBytes, 40);

  for (let i = 0; i < samples.length; i += 1) {
    const bounded = clamp(samples[i], -0.999969, 0.999969);
    const pcm = Math.round(bounded * 32767);
    wav.writeInt16LE(pcm, 44 + i * 2);
  }

  fs.writeFileSync(filePath, wav);
}

function findChunk(wav, wantedId) {
  let offset = 12;
  while (offset + 8 <= wav.length) {
    const id = wav.toString('ascii', offset, offset + 4);
    const size = wav.readUInt32LE(offset + 4);
    const dataOffset = offset + 8;
    const nextOffset = dataOffset + size + (size & 1);
    if (nextOffset > wav.length) throw new Error(`RIFF bloku fayl sərhədini aşır: ${id}`);
    if (id === wantedId) return { dataOffset, size };
    offset = nextOffset;
  }
  throw new Error(`RIFF bloku tapılmadı: ${wantedId}`);
}

// Yazılmış fayl yenidən oxunur; bununla başlıq və real PCM birlikdə yoxlanılır.
function inspectWav(filePath, spec) {
  const wav = fs.readFileSync(filePath);
  if (wav.length < 44) throw new Error(`${spec.file}: WAV başlığı natamamdır.`);
  if (wav.toString('ascii', 0, 4) !== 'RIFF' || wav.toString('ascii', 8, 12) !== 'WAVE') {
    throw new Error(`${spec.file}: RIFF/WAVE imzası yanlışdır.`);
  }
  if (wav.readUInt32LE(4) + 8 !== wav.length) throw new Error(`${spec.file}: RIFF ölçüsü yanlışdır.`);

  const fmt = findChunk(wav, 'fmt ');
  const data = findChunk(wav, 'data');
  if (fmt.size < 16) throw new Error(`${spec.file}: fmt bloku natamamdır.`);
  if (wav.readUInt16LE(fmt.dataOffset) !== 1) throw new Error(`${spec.file}: PCM formatında deyil.`);
  if (wav.readUInt16LE(fmt.dataOffset + 2) !== CHANNELS) throw new Error(`${spec.file}: mono deyil.`);
  if (wav.readUInt32LE(fmt.dataOffset + 4) !== SAMPLE_RATE) throw new Error(`${spec.file}: 44100 Hz deyil.`);
  if (wav.readUInt32LE(fmt.dataOffset + 8) !== 88200) throw new Error(`${spec.file}: byte rate yanlışdır.`);
  if (wav.readUInt16LE(fmt.dataOffset + 12) !== 2) throw new Error(`${spec.file}: block align yanlışdır.`);
  if (wav.readUInt16LE(fmt.dataOffset + 14) !== BITS_PER_SAMPLE) throw new Error(`${spec.file}: 16-bit deyil.`);
  if (data.size === 0 || data.size % 2 !== 0) throw new Error(`${spec.file}: PCM məlumat ölçüsü yanlışdır.`);

  const frames = data.size / 2;
  const duration = frames / SAMPLE_RATE;
  const withinLimit = spec.strictLimit ? duration < spec.limit : duration <= spec.limit;
  if (!withinLimit) throw new Error(`${spec.file}: müddət həddi aşılıb (${duration.toFixed(6)} s).`);

  let peak = 0;
  let sumSquares = 0;
  let sum = 0;
  let firstEdgePeak = 0;
  let lastEdgePeak = 0;
  const edgeFrames = Math.min(frames, 22);

  for (let frame = 0; frame < frames; frame += 1) {
    const sample = wav.readInt16LE(data.dataOffset + frame * 2);
    const absolute = Math.abs(sample);
    peak = Math.max(peak, absolute);
    sumSquares += sample * sample;
    sum += sample;
    if (frame < edgeFrames) firstEdgePeak = Math.max(firstEdgePeak, absolute);
    if (frame >= frames - edgeFrames) lastEdgePeak = Math.max(lastEdgePeak, absolute);
    if (sample === -32768 || sample === 32767) throw new Error(`${spec.file}: tam miqyaslı nümunə tapıldı.`);
  }

  if (peak === 0) throw new Error(`${spec.file}: fayl səssizdir.`);
  if (wav.readInt16LE(data.dataOffset) !== 0 || wav.readInt16LE(data.dataOffset + data.size - 2) !== 0) {
    throw new Error(`${spec.file}: fade ucları sıfır deyil.`);
  }
  if (firstEdgePeak / peak > 0.35 || lastEdgePeak / peak > 0.35) {
    throw new Error(`${spec.file}: kənar fade yoxlamasından keçmədi.`);
  }

  const rms = Math.sqrt(sumSquares / frames) / 32768;
  return {
    file: spec.file,
    frames,
    duration,
    bytes: wav.length,
    peakGain: peak / 32768,
    peakDb: 20 * Math.log10(peak / 32768),
    rmsDb: 20 * Math.log10(rms),
    dc: sum / frames / 32768,
  };
}

function run() {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  for (const spec of SOUND_SPECS) {
    const samples = spec.create(spec);
    writeWav(path.join(OUTPUT_DIR, spec.file), samples);
  }

  const reports = SOUND_SPECS.map((spec) => inspectWav(path.join(OUTPUT_DIR, spec.file), spec));
  const expectedNames = new Set(SOUND_SPECS.map((spec) => spec.file));
  const actualNames = fs.readdirSync(OUTPUT_DIR).filter((name) => name.toLowerCase().endsWith('.wav'));
  const unexpected = actualNames.filter((name) => !expectedNames.has(name));
  const missing = [...expectedNames].filter((name) => !actualNames.includes(name));
  if (missing.length) throw new Error(`Çatışmayan WAV faylları: ${missing.join(', ')}`);
  if (unexpected.length) throw new Error(`Gözlənilməyən WAV faylları: ${unexpected.join(', ')}`);

  const totalBytes = reports.reduce((total, report) => total + report.bytes, 0);
  if (totalBytes >= 1_500_000) throw new Error(`Ümumi ölçü 1.5 MB həddini aşır: ${totalBytes} bayt.`);

  console.table(reports.map((report) => ({
    fayl: report.file,
    'müddət (ms)': (report.duration * 1000).toFixed(1),
    'ölçü (KiB)': (report.bytes / 1024).toFixed(1),
    'pik (dBFS)': report.peakDb.toFixed(2),
    'RMS (dBFS)': report.rmsDb.toFixed(2),
    'DC': report.dc.toExponential(2),
  })));
  console.log(`Yoxlama tamamlandı: ${reports.length} WAV, ${(totalBytes / 1024).toFixed(1)} KiB.`);
}

run();
