// ===== 1. Desplegables de experiencia =====
document.querySelectorAll('.item-cabecera').forEach((boton) => {
  boton.addEventListener('click', () => {
    const item = boton.parentElement;
    const detalle = item.querySelector('.item-detalle');
    const abierto = item.classList.toggle('abierto');
    boton.setAttribute('aria-expanded', abierto);
    detalle.style.maxHeight = abierto ? detalle.scrollHeight + 'px' : '0';
  });
});

// ===== 2. Filtro de habilidades =====
const chips = document.querySelectorAll('.chip');
const habilidades = document.querySelectorAll('.habilidades li');

chips.forEach((chip) => {
  chip.addEventListener('click', () => {
    chips.forEach((c) => c.classList.remove('activo'));
    chip.classList.add('activo');
    const filtro = chip.dataset.filtro;
    habilidades.forEach((li) => {
      li.classList.toggle('oculta', filtro !== 'todas' && li.dataset.cat !== filtro);
    });
  });
});

// ===== 3. Validación del formulario de contacto =====
const form = document.getElementById('form-contacto');
const regexCorreo = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

function marcar(id, mensaje) {
  const campo = document.getElementById(id);
  document.getElementById('error-' + id).textContent = mensaje;
  campo.classList.toggle('invalido', mensaje !== '');
  return mensaje === '';
}

form.addEventListener('submit', (e) => {
  e.preventDefault();
  const nombre = form.nombre.value.trim();
  const correo = form.correo.value.trim();
  const mensaje = form.mensaje.value.trim();

  const ok = [
    marcar('nombre', nombre.length >= 3 ? '' : 'Escribe tu nombre (mínimo 3 letras).'),
    marcar('correo', regexCorreo.test(correo) ? '' : 'Ingresa un correo válido.'),
    marcar('mensaje', mensaje.length >= 10 ? '' : 'El mensaje debe tener al menos 10 caracteres.'),
  ].every(Boolean);

  document.getElementById('form-ok').hidden = !ok;
  if (!ok) return;

  // Sin servidor: se arma un correo y lo abre la app de correo del teléfono
  const asunto = encodeURIComponent('Contacto desde CV - ' + nombre);
  const cuerpo = encodeURIComponent(mensaje + '\n\nResponder a: ' + correo);
  window.location.href = `mailto:Michaelparedes1994@hotmail.com?subject=${asunto}&body=${cuerpo}`;
  form.reset();
});

// ===== 4. Resaltar en el menú la sección visible =====
const menu = document.querySelector('.menu');
const enlaces = menu.querySelectorAll('a');
const observador = new IntersectionObserver((entradas) => {
  entradas.forEach((entrada) => {
    if (!entrada.isIntersecting) return;
    enlaces.forEach((a) => {
      const activo = a.getAttribute('href') === '#' + entrada.target.id;
      a.classList.toggle('activo', activo);
      if (activo) menu.scrollLeft = a.offsetLeft - menu.clientWidth / 2 + a.offsetWidth / 2;
    });
  });
}, { rootMargin: '-40% 0px -55% 0px' });
document.querySelectorAll('main .seccion').forEach((s) => observador.observe(s));

// ===== 5. Funciones que llama la app Flutter (puente nativo → web) =====
window.setTheme = function (modo) {
  document.documentElement.setAttribute('data-theme', modo); // 'light' | 'dark'
};
window.irA = function (id) {
  const destino = document.getElementById(id);
  if (destino) destino.scrollIntoView({ behavior: 'smooth' });
};
