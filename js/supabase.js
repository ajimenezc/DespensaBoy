// Configuración de Supabase
// IMPORTANTE: Reemplaza estas variables con tus credenciales de Supabase
// Obtén estas credenciales en: https://supabase.com/dashboard/project/_/settings/api

const SUPABASE_URL = 'https://nbwupfaryhheigvvbxyj.supabase.co'; // Ej: https://abcdefghijklmnop.supabase.co
const SUPABASE_ANON_KEY = 'sb_publishable_RDi-ZBfJdDcXPmb3mTwrcQ_ivQZsTD0'; // Tu clave anónima pública

// Cliente de Supabase (se inicializa cuando se carga el SDK)
let supabaseClient = null;

// Inicializar cliente de Supabase
function initSupabase() {
  if (typeof supabase === 'undefined') {
    console.warn('Supabase SDK no está cargado');
    return false;
  }

  if (!supabaseClient) {
    supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }

  return true;
}

// Generar código familiar único
function generarCodigoFamiliar() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sin caracteres confusos (0, O, 1, I)
  let codigo = 'DESPENSA-';
  for (let i = 0; i < 8; i++) {
    codigo += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return codigo;
}

// Crear nueva despensa con código
async function crearDespensaConCodigo() {
  if (!initSupabase()) {
    throw new Error('Supabase no está disponible');
  }

  const codigo = generarCodigoFamiliar();

  const { data, error } = await supabaseClient
    .from('despensas')
    .insert({
      codigo: codigo,
      raciones: state.raciones,
      historico: state.racionesHistorico,
    })
    .select()
    .single();

  if (error) {
    console.error('Error creando despensa:', error);
    throw error;
  }

  return codigo;
}

// Conectar con código existente
async function conectarConCodigo(codigo) {
  if (!initSupabase()) {
    throw new Error('Supabase no está disponible');
  }

  const { data, error } = await supabaseClient
    .from('despensas')
    .select('*')
    .eq('codigo', codigo.toUpperCase())
    .single();

  if (error) {
    console.error('Error conectando:', error);
    throw new Error('Código no encontrado');
  }

  return data;
}

// Sincronizar datos locales con Supabase
async function sincronizarConSupabase(codigo) {
  if (!initSupabase()) {
    return false;
  }

  const timestamp = new Date().toISOString();

  const { error } = await supabaseClient
    .from('despensas')
    .update({
      raciones: state.raciones,
      historico: state.racionesHistorico,
      updated_at: timestamp,
    })
    .eq('codigo', codigo);

  if (error) {
    console.error('Error sincronizando:', error);
    return false;
  }

  // Guardar timestamp local para evitar loops
  localStorage.setItem('last_update_timestamp', timestamp);

  return true;
}

// Suscribirse a cambios en tiempo real
function suscribirseACambios(codigo) {
  if (!initSupabase()) {
    return null;
  }

  const channel = supabaseClient
    .channel('despensa-changes')
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'despensas',
        filter: `codigo=eq.${codigo}`,
      },
      (payload) => {
        // Solo actualizar si el cambio viene de otro dispositivo
        const localTimestamp = localStorage.getItem('last_update_timestamp');
        const remoteTimestamp = payload.new.updated_at;

        if (remoteTimestamp !== localTimestamp) {
          console.log('📥 Recibiendo cambios de otro dispositivo...');
          state.raciones = payload.new.raciones || [];
          state.racionesHistorico = payload.new.historico || [];

          // Actualizar localStorage
          saveDataLocal(state.raciones, state.racionesHistorico);

          // Re-renderizar
          render();
        }
      }
    )
    .subscribe();

  return channel;
}

// Desuscribirse de cambios
function desuscribirseACambios(channel) {
  if (channel) {
    supabaseClient.removeChannel(channel);
  }
}

// Guardar datos solo en localStorage (sin sincronizar)
function saveDataLocal(raciones, racionesHistorico) {
  localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify({ raciones, racionesHistorico }));
}

// Verificar si Supabase está configurado correctamente
function isSupabaseConfigured() {
  return SUPABASE_URL !== 'TU_SUPABASE_URL' &&
         SUPABASE_ANON_KEY !== 'TU_SUPABASE_ANON_KEY';
}
