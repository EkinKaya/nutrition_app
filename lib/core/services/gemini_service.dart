import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'user_service.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  static List<Map<String, dynamic>> _history = [];

  /// Kullanici bilgileriyle sistem promptu olusturur
  static Future<String> _buildSystemPrompt() async {
    final userData = await UserService.getFullUserContext();

    String userContext = '';
    bool hasUserData = false;
    bool hasPdfData = false;

    if (userData != null) {
      final email = userData['email'];
      final age = userData['age'];
      final weight = userData['weight'];
      final height = userData['height'];
      final gender = userData['gender'];
      final dietType = userData['dietType'];
      final pdfContent = userData['pdfContent'];

      // Kullanici verisi var mi kontrol et
      if (age != null || weight != null || height != null) {
        hasUserData = true;
      }

      userContext = '''

KULLANICI PROFIL BILGILERI (Bu bilgilere sahipsin ve kullanabilirsin):
- Email: ${email ?? 'Belirtilmedi'}
- Yas: ${age ?? 'Belirtilmedi'}
- Kilo: ${weight != null ? '$weight kg' : 'Belirtilmedi'}
- Boy: ${height != null ? '$height cm' : 'Belirtilmedi'}
- Cinsiyet: ${gender ?? 'Belirtilmedi'}
- Beslenme Tercihi: ${dietType ?? 'Belirtilmedi'}
''';

      if (pdfContent != null && pdfContent.isNotEmpty) {
        hasPdfData = true;
        userContext += '''

KULLANICININ KAN TESTI SONUCLARI (Bu verilere sahipsin ve analiz edebilirsin):
$pdfContent
''';
      }
    }

    String accessInfo = '';
    if (hasUserData) {
      accessInfo += '- Kullanicinin profil bilgilerine (yas, kilo, boy, cinsiyet) erisimin VAR\n';
    }
    if (hasPdfData) {
      accessInfo += '- Kullanicinin kan testi sonuclarina erisimin VAR, bu verileri analiz edebilirsin\n';
    }

    return '''Sen bir beslenme ve saglik asistanisin. Adin "Beslenme Arkadasi".

GOREVLERIN:
1. Yemek tarifleri onerme ve paylasma
2. Beslenme tavsiyeleri verme
3. Saglikli yasam onerileri sunma
4. Kullanicinin kan testi sonuclarina gore ozel oneriler yapma
5. Kilo kontrolu ve diyet konularinda yardimci olma

ERISIM BILGISI:
$accessInfo
KURALLAR:
- Sadece beslenme, saglik, yemek tarifleri ve saglikli yasam konularinda yardimci ol
- Diger konularda kibarca "Bu konuda yardimci olamiyorum, sadece beslenme ve saglik konularinda destek verebilirim" de
- Turkce konusuyorsun
- Kisa ve oz cevaplar ver, gereksiz uzatma
- ONEMLI: Yemek tarifi verirken MUTLAKA "Tarif:" kelimesiyle basla (ornek: "Tarif: Mercimek Corbasi"). Sonra malzemeler ve yapilis adimlarini listele
- Saglik tavsiyeleri verirken dikkatli ol, ciddi durumlarda doktora yonlendir
- Kullanici bilgilerini sorularinda kullan (eger mevcutsa)
- Kullanici "bilgilerime erisebiliyor musun" diye sorarsa, yukaridaki erisim bilgisine gore cevap ver
$userContext

Kullaniciya kisisel ve faydali oneriler sun.''';
  }

  /// Yeni sohbet baslatir
  static Future<void> startNewChat() async {
    _history = [];
    final systemPrompt = await _buildSystemPrompt();

    // Sistem promptunu history'e ekle
    _history.add({
      'role': 'user',
      'parts': [{'text': systemPrompt}]
    });
    _history.add({
      'role': 'model',
      'parts': [{'text': 'Anlasıldı. Ben Beslenme Arkadası olarak sadece beslenme, sağlık ve yemek tarifleri konularında yardımcı olacağım.'}]
    });
  }

  /// Mesaj gonderir ve yanit alir
  static Future<String> sendMessage(String message) async {
    if (_history.isEmpty) {
      await startNewChat();
    }

    // Kullanici mesajini ekle
    _history.add({
      'role': 'user',
      'parts': [{'text': message}]
    });

    try {
      final url = '$_baseUrl?key=${ApiConfig.geminiApiKey}';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': _history,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Yanit alinamadi';

        // Model yanitini history'e ekle
        _history.add({
          'role': 'model',
          'parts': [{'text': text}]
        });

        return text;
      } else {
        final error = jsonDecode(response.body);
        return 'Hata: ${error['error']?['message'] ?? response.statusCode}';
      }
    } catch (e) {
      print('Gemini API Hata Detayi: $e');
      return 'Baglanti hatasi: $e';
    }
  }

  /// API anahtarini test eder ve mevcut modelleri listeler
  static Future<String> testApiKey() async {
    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=${ApiConfig.geminiApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List?;
        if (models != null && models.isNotEmpty) {
          // generateContent destekleyen modelleri filtrele
          final generateModels = models.where((m) {
            final methods = m['supportedGenerationMethods'] as List?;
            return methods != null && methods.contains('generateContent');
          }).toList();

          final modelNames = generateModels.take(10).map((m) => m['name']).join('\n');
          return 'Modeller:\n$modelNames';
        }
        return 'API calisiyor ama model listesi bos.';
      } else {
        final error = jsonDecode(response.body);
        return 'API Hatasi: ${error['error']?['message'] ?? response.statusCode}\nStatus: ${response.statusCode}';
      }
    } catch (e) {
      return 'Test hatasi: $e';
    }
  }

  /// Sohbeti sifirlar
  static void resetChat() {
    _history = [];
  }
}
