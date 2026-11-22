// usage: node live.js '<json>' [port]
const net = require('net');
const port = parseInt(process.argv[3] || process.env.LIVE_PORT || '7777');
const msg = process.argv[2] || '{"cmd":"state"}';
const s = net.createConnection({ port, host: '127.0.0.1' }, () => s.write(msg + '\n'));
let buf = '';
s.setTimeout(180000);
s.on('data', d => { buf += d.toString('utf8'); const i = buf.indexOf('\n'); if (i >= 0) { const out = buf.slice(0, i); try { console.log(JSON.stringify(JSON.parse(out), null, 0)); } catch (e) { console.log(out); } s.end(); } });
s.on('timeout', () => { console.log('TIMEOUT'); s.destroy(); process.exit(2); });
s.on('error', e => { console.log('ERR ' + e.message); process.exit(1); });
