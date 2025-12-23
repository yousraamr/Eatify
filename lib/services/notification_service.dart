import '../services/supabase_service.dart';

class NotificationService {
  static Future<void> create({
    required String userId,
    required String title,
    required String body,
  }) async {
    await SupabaseService.client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
    });
  }
}
