/// Configuração do Supabase
abstract class SupabaseConfig {
  /// URL do projeto Supabase
  static const String url = 'https://hxdlbtvsvlfmjzujtnve.supabase.co';

  /// Anon Key do Supabase
  static const String anonKey = 'sb_publishable_D8FLXvCCAawuErKdO5jJAg_4cGGjSQO';

  /// Verifica se está configurado
  static bool get isConfigured =>
      url != 'YOUR_SUPABASE_URL' && anonKey != 'YOUR_SUPABASE_ANON_KEY';
}
