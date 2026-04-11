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
      return data['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String?;
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

  /// Yiyecek/tarif için porsiyon besin değerlerini hesaplar (chat history'ye eklenmez)
  static Future<Map<String, double>> getNutritionalInfo(
      String foodDescription, int portionGrams) async {
    final desc = foodDescription.length > 800
        ? foodDescription.substring(0, 800)
        : foodDescription;

    final prompt = '$portionGrams gramlık porsiyon için yaklaşık besin değerlerini hesapla.\n'
        'Yanıtın SADECE aşağıdaki JSON olsun, başka hiçbir şey yazma:\n'
        '{"calories":250,"protein":15,"carbs":30,"fat":8}\n\n'
        'Yiyecek/Tarif:\n$desc';

    for (final model in _models) {
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
                  'maxOutputTokens': 80,
                }
              }),
            )
            .timeout(const Duration(seconds: 20));

        debugPrint('NutritionalInfo [$model] → ${resp.statusCode}');

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final raw = data['candidates']?[0]?['content']?['parts']?[0]?['text']
                  as String? ??
              '';
          debugPrint('NutritionalInfo raw: $raw');

          // Markdown code fence ve boşlukları temizle
          final clean =
              raw.replaceAll('```json', '').replaceAll('```', '').trim();

          // İlk { ... } bloğunu al
          final start = clean.indexOf('{');
          final end = clean.lastIndexOf('}');
          if (start != -1 && end > start) {
            try {
              final j = jsonDecode(clean.substring(start, end + 1))
                  as Map<String, dynamic>;
              return {
                'calories': (j['calories'] as num?)?.toDouble() ?? 0,
                'protein': (j['protein'] as num?)?.toDouble() ?? 0,
                'carbs': (j['carbs'] as num?)?.toDouble() ?? 0,
                'fat': (j['fat'] as num?)?.toDouble() ?? 0,
              };
            } catch (e) {
              debugPrint('NutritionalInfo parse error: $e');
            }
          }
        }

        if (resp.statusCode != 503 &&
            resp.statusCode != 429 &&
            resp.statusCode != 404) break;
      } catch (e) {
        debugPrint('NutritionalInfo exception: $e');
        break;
      }
    }
    return {};
  }

  /// Sohbeti sifirlar
  static void resetChat() {
    _history = [];
  }
}
