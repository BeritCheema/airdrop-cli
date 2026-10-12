const scenarios = {
  photo: {
    command: 'airdrop-cli ~/Pictures/photo.png',
    target: 'ipon',
    icon: '▧',
    title: ['Photo sent', 'to ipon.'],
    caption: 'A picture moves from your Mac to your phone.'
  },
  link: {
    command: 'airdrop-cli https://example.com',
    target: 'ipon',
    icon: '↗',
    title: ['Link sent', 'to ipon.'],
    caption: 'A URL goes straight to your phone through AirDrop.'
  }
};

const lines = document.querySelector('#terminal-lines');
const buttons = document.querySelectorAll('.scenario');
const replay = document.querySelector('#replay-demo');
const result = document.querySelector('.demo-result');
let active = 'photo';
let timers = [];

function clearTimers() {
  timers.forEach(clearTimeout);
  timers = [];
}

function appendLine(className, content) {
  const line = document.createElement('div');
  line.className = 'terminal-line ' + className;
  line.textContent = content;
  lines.append(line);
}

function setResultTitle(parts) {
  const title = document.querySelector('#result-title');
  title.replaceChildren(parts[0], document.createElement('br'), parts[1]);
}

function playDemo(name) {
  clearTimers();
  active = name;
  const scenario = scenarios[name];
  buttons.forEach(button => {
    const selected = button.dataset.scenario === name;
    button.classList.toggle('is-active', selected);
    button.setAttribute('aria-pressed', String(selected));
  });
  lines.replaceChildren();
  result.classList.remove('is-sent');
  document.querySelector('#result-icon').textContent = '↗';
  document.querySelector('#result-kicker').textContent = 'READY TO RECEIVE';
  setResultTitle(['From command', 'to pocket.']);
  document.querySelector('#result-caption').textContent = 'Your saved device is ready.';
  appendLine('command', '$ ' + scenario.command);

  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const schedule = (callback, delay) => timers.push(setTimeout(callback, reducedMotion ? 0 : delay));
  schedule(() => appendLine('progress', 'Sending to ' + scenario.target + '…'), 580);
  schedule(() => {
    appendLine('success', '✓ Sent 1 item to ' + scenario.target);
    result.classList.add('is-sent');
    document.querySelector('#result-icon').textContent = scenario.icon;
    document.querySelector('#result-kicker').textContent = 'SENT VIA AIRDROP';
    setResultTitle(scenario.title);
    document.querySelector('#result-caption').textContent = scenario.caption;
  }, 1850);
}

buttons.forEach(button => button.addEventListener('click', () => playDemo(button.dataset.scenario)));
replay.addEventListener('click', () => playDemo(active));
playDemo(active);

document.querySelector('#copy-install').addEventListener('click', async event => {
  const commands = [
    'git clone https://github.com/BeritCheema/airdrop-cli.git',
    'cd airdrop-cli && make install',
    'airdrop-cli setup',
    'airdrop-cli ~/Pictures/photo.png'
  ].join('\n');
  try {
    await navigator.clipboard.writeText(commands);
    event.currentTarget.textContent = 'Copied';
    setTimeout(() => { event.currentTarget.textContent = 'Copy'; }, 1800);
  } catch {
    event.currentTarget.textContent = 'Select commands to copy';
  }
});
