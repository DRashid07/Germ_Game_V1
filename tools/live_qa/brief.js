// node brief.js '<json>' [port]  -> compact output
const net = require('net');
const port = parseInt(process.argv[3] || process.env.LIVE_PORT || '7777');
const msg = process.argv[2] || '{"cmd":"state"}';
const s = net.createConnection({ port, host: '127.0.0.1' }, () => s.write(msg + '\n'));
let buf = '';
s.setTimeout(300000);
function fmtState(st) {
  if (!st) return '';
  let o = `[${st.scene} t=${st.t} fps=${st.fps} err=${st.errors_total} spikes=${st.spikes}`;
  if (st.scene === 'Arena') {
    o += ` mode=${st.mode} ph=${st.phase}@${st.phase_t} wet=${st.wet_r}${st.finished ? ' FINISHED' : ''}${st.hidden ? ' BUSH' : ''}]`;
    const m = st.me; if (m) o += `\n me pos=${m.pos} v=${m.vel} balls=${m.balls}/${m.cap} chg=${m.charge}${m.super_ready ? '(READY)' : ''} sup_t=${m.super_t} cd=${m.cd} safe=${m.safe} mem_cd=${m.mem_cd}${m.mem_ready ? '(MR)' : ''} pops=${m.pops} age=${m.age}${m.dead_wait ? ' DEADWAIT' : ''}${m.alive ? '' : ' DEAD'}`;
    if (st.germs) o += '\n germs: ' + st.germs.slice(0, 5).map(g => `${g.mate ? 'M' : 'E'}${g.id % 1000} d${g.d} (${g.dir}) ${g.balls}/${g.cap}`).join(' | ');
    if (st.food) o += `\n food d${st.food.d} @${st.food.pos}`;
    if (st.hud) { const h = Object.assign({}, st.hud); delete h.board_lbl; o += '\n hud: ' + JSON.stringify(h); }
  } else o += ']';
  return o;
}
s.on('data', d => { buf += d.toString('utf8'); const i = buf.indexOf('\n'); if (i >= 0) { const r = JSON.parse(buf.slice(0, i)); 
  if (r.error) console.log('ERROR', r.error);
  if (r.what) console.log('clicked:', r.what);
  if (r.log && r.log.length) console.log('log:', r.log.join('; '));
  if (r.shot) console.log('shot:', r.shot);
  if (r.shots) console.log('shots:', r.shots.join(' '));
  if (r.value !== undefined) console.log('value:', r.value);
  if (r.errors) console.log('errors:', JSON.stringify(r.errors));
  if (r.ui) r.ui.forEach(x => console.log(JSON.stringify(x)));
  const st = r.scene ? r : r.state; if (st) console.log(fmtState(st));
  s.end(); } });
s.on('timeout', () => { console.log('TIMEOUT'); s.destroy(); process.exit(2); });
s.on('error', e => { console.log('ERR ' + e.message); process.exit(1); });
