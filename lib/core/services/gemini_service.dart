import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'user_service.dart';

class GeminiService {
  static const String _baseEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Sırayla denenen modeller: birincisi 503 verirse ikinciye geçer
  static const List<String> _models = [
    'gemini-2.0-flash-lite',  // En hafif, en geniş kota
    'gemini-2.0-flash',       // Orta
    'gemini-2.5-flash',       // Yedek
  ];

  static List<Map<String, dynamic>> _history = [];

  static String _url(String model) =>
      '$_baseEndpoint/$model:generateContent?key=${ApiConfig.geminiApiKey}';

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

    return '''Sen bir beslenme ve saglik asistanisin. Adin "Beslenme Arkadasi".

GOREVLERIN:
1. Yemek tarifleri onerme ve paylasma
2. Beslenme tavsiyeleri verme
3. Saglikli yasam onerileri sunma
4. Kullanicinin kan testi sonuclarina gore ozel oneriler yapma
5. Kilo kontrolu ve diyet konularinda yardimci olma

KULLANICI BILGILERI (sessizce kullan, kullaniciya bunlari tekrar SÖYLEME):
$userContext

KURALLAR:
- Sadece beslenme, saglik, yemek tarifleri ve saglikli yasam konularinda yardimci ol
- Diger konularda kibarca "Bu konuda yardimci olamiyorum" de
- Turkce konusuyorsun, kisa ve oz cevaplar ver
- Kullanicinin yas/kilo/boy gibi bilgilerini ona tekrar SÖYLEME; bu bilgileri sadece onerileri kisiselleştirmek icin kullan
- KRITIK: Yemek tarifi verirken yanit MUTLAKA "Tarif: [Yemek Adi]" satiriyla BASMALI. Bu satirdan once hicbir giris cumlesi olmamali. Ardindan Malzemeler ve Hazirlik bolumlerini listele.
- Saglik tavsiyeleri verirken dikkatli ol, ciddi durumlarda doktora yonlendir
- Kullanici "bilgilerime erisebiliyor musun" diye sorarsa "Evet, profil bilgilerine erisimim var" de

Kullaniciya kisisel ve faydali oneriler sun.''';
  }

  /// Yeni sohbet baslatir
  static Future<void> startNewChat() async {
    _history = [];
    final systemPrompt = await _buildSystemPrompt();

    _history.add({
      'role': 'user',
      'parts': [{'text': systemPrompt}]
    });
    _history.add({
      'role': 'model',
      'parts': [
        {
          'text':
              'Anlasıldı. Ben Beslenme Arkadası olarak sadece beslenme, sağlık ve yemek tarifleri konularında yardımcı olacağım.'
        }
      ]
    });
  }

  /// Tek bir modele istek atar. 200 ise yanıtı, 503/429 ise null döner, diğer hatalar exception fırlatır.
  static Future<String?> _tryModel(String model) async {
    final response = await http
        .post(
          Uri.parse(_url(model)),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': _history,
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 1024,
            }
          }),
        )
        .timeout(const Duration(seconds: 20));

    debugPrint('GeminiService [$model] → HTTP ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final parts = data['candidates']?[0]?['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;
      return parts.map((p) => (p['text'] as String?) ?? '').join('');
    }

    debugPrint('GeminiService [$model] body: ${response.body.substring(0, response.body.length.clamp(0, 300))}');

    // Kapasite sorunu veya model bulunamadı → sıradaki modeli dene
    if (response.statusCode == 503 ||
        response.statusCode == 429 ||
        response.statusCode == 404) {
      return null;
    }

    // Diğer hatalar (401, 400 vb.)
    final err = jsonDecode(response.body);
    throw Exception(err['error']?['message'] ?? response.statusCode);
  }

  /// Mesaj gonderir: modelleri sırayla dener
  static Future<String> sendMessage(String message) async {
    if (_history.isEmpty) {
      await startNewChat();
    }

    _history.add({
      'role': 'user',
      'parts': [{'text': message}]
    });

    try {
      for (int m = 0; m < _models.length; m++) {
        final model = _models[m];
        // Her model için 2 deneme
        for (int attempt = 0; attempt < 2; attempt++) {
          if (attempt > 0) {
            await Future.delayed(const Duration(seconds: 4));
          }
          try {
            final text = await _tryModel(model);
            if (text != null) {
              _history.add({
                'role': 'model',
                'parts': [{'text': text}]
              });
              return text;
            }
            // null → 503/429/404
            // 503/429 için kısa bekle; 404 ise hemen sonraki modele geç
            if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
          } catch (_) {
            break;
          }
        }
      }

      // Tüm modeller başarısız
      _history.removeLast();
      return 'Sunucular şu an meşgul. Birkaç saniye bekleyip tekrar dene.';
    } catch (e) {
      _history.removeLast();
      return 'Bağlantı hatası. İnternet bağlantını kontrol et.';
    }
  }

  /// Yiyecek/tarif için porsiyon besin değerlerini hesaplar.
  /// responseSchema kullanarak modeli 4 alanı TAMAMLAMAYA zorlar.
  static Future<Map<String, double>> getNutritionalInfo(
      String foodDescription, int portionGrams,
      {Map<String, double?> userValues = const {}}) async {
    final desc = foodDescription.length > 600
        ? foodDescription.substring(0, 600)
        : foodDescription;

    final filled = <String>[];
    if ((userValues['calories'] ?? 0) > 0) filled.add('calories:${userValues['calories']!.round()}');
    if ((userValues['protein'] ?? 0) > 0) filled.add('protein:${userValues['protein']!.toStringAsFixed(1)}');
    if ((userValues['carbs'] ?? 0) > 0) filled.add('carbs:${userValues['carbs']!.toStringAsFixed(1)}');
    if ((userValues['fat'] ?? 0) > 0) filled.add('fat:${userValues['fat']!.toStringAsFixed(1)}');
    final userHint = filled.isEmpty
        ? ''
        : 'User already provided: ${filled.join(', ')} — keep these exact values.\n';

    // Her değer kendi satırında → regex ile kesin parse edilir
    final prompt =
        'Food: $desc\n'
        'Portion: $portionGrams grams\n'
        '${userHint}'
        'Complete each line with an integer (no units, no extra text):\n'
        'calories=\n'
        'protein=\n'
        'carbs=\n'
        'fat=';

    for (int m = 0; m < _models.length; m++) {
      final model = _models[m];
      for (int attempt = 0; attempt < 2; attempt++) {
        if (attempt > 0) await Future.delayed(const Duration(seconds: 4));
        try {
          final resp = await http
              .post(
                Uri.parse(_url(model)),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'contents': [
                    {
                      'role': 'user',
                      'parts': [{'text': prompt}]
                    }
                  ],
                  'generationConfig': {
                    'temperature': 0.1,
                    'maxOutputTokens': 64,
                  }
                }),
              )
              .timeout(const Duration(seconds: 25));

          debugPrint('NutritionalInfo [$model] attempt $attempt → ${resp.statusCode}');

          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            final parts = data['candidates']?[0]?['content']?['parts'] as List?;
            final raw = parts == null
                ? ''
                : parts.map((p) => (p['text'] as String?) ?? '').join('');
            debugPrint('NutritionalInfo raw: $raw');

            // "calories=315\nprotein=18\ncarbs=54\nfat=12" formatını regex ile parse et
            double? _val(String key) {
              final m = RegExp(
                '$key\\s*=\\s*(\\d+(?:\\.\\d+)?)',
                caseSensitive: false,
              ).firstMatch(raw);
              return m != null ? double.tryParse(m.group(1)!) : null;
            }

            final cal  = _val('calories');
            final prot = _val('protein');
            final carb = _val('carbs');
            final fat  = _val('fat');

            debugPrint('NutritionalInfo parsed: cal=$cal prot=$prot carb=$carb fat=$fat');

            if (cal != null && prot != null && carb != null && fat != null) {
              return {'calories': cal, 'protein': prot, 'carbs': carb, 'fat': fat};
            }
            debugPrint('NutritionalInfo: missing values, trying next model');
            break;
          }

          if (resp.statusCode == 503 ||
              resp.statusCode == 429 ||
              resp.statusCode == 404) {
            if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
            continue;
          }

          debugPrint('NutritionalInfo error: ${resp.statusCode} | ${resp.body.substring(0, resp.body.length.clamp(0, 200))}');
          return {};
        } catch (e) {
          debugPrint('NutritionalInfo exception [$model]: $e');
          break;
        }
      }
    }
    return {};
  }

  /// Sohbeti sifirlar
  static void resetChat() {
    _history = [];
  }
}
