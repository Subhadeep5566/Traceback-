import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/asset.dart';
import '../models/incident.dart';

class AIService {
  GenerativeModel? _model;
  bool _isInitialized = false;
  String? _apiKey;

  static const String _systemPrompt = '''
You are Traceback AI, a specialized recovery assistant for the Traceback asset tracking platform at BGU (Birla Global University).

Your role is to help users understand and act on active recovery situations. You have access to incident data, asset information, and location history.

Guidelines:
- Be concise and actionable (2-4 sentences max)
- Focus on the current recovery situation
- Use the provided context data
- Never make up information not in the context
- If data is missing, say so clearly
- Tone: professional, calm, helpful

Capabilities:
- Summarize the incident
- Analyze last known location and detection history
- Generate recovery guidance
- Create concise incident reports
- Answer questions about the current recovery

Do NOT:
- Provide generic chatbot responses
- Speculate beyond the data
- Share personal opinions
- Discuss topics outside Traceback recovery
''';

  Future<void> initialize(String apiKey) async {
    if (_isInitialized && _apiKey == apiKey) return;
    
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 500,
      ),
    );
    _isInitialized = true;
  }

  bool get isAvailable => _isInitialized && _model != null && _apiKey != null && _apiKey!.isNotEmpty;

  Future<String?> _generateResponse(String prompt) async {
    if (!isAvailable) return null;
    
    try {
      final response = await _model!.generateContent([
        Content.text(prompt),
      ]).timeout(const Duration(seconds: 15));
      
      return response.text?.trim();
    } on TimeoutException {
      return 'AI request timed out. Please try again.';
    } catch (e) {
      return 'AI service temporarily unavailable: ${e.toString()}';
    }
  }

  Future<String?> summarizeIncident(Incident incident, Asset asset) async {
    final prompt = '''
Incident Summary Request:
- Asset: ${asset.name} (${asset.identifier})
- Category: ${asset.category.displayName}
- Incident ID: ${incident.id}
- Type: ${incident.type}
- Status: ${incident.status}
- Reported: ${incident.timestamp.toIso8601String()}
- Last Known Location: ${asset.address} (${asset.latitude.toStringAsFixed(4)}° N, ${asset.longitude.toStringAsFixed(4)}° E)
- Description: ${incident.description}

Detection Timeline:
${incident.timeline.map((t) => '- ${t.timestamp.toIso8601String()}: ${t.title} - ${t.description}').join('\n')}

Provide a concise 2-3 sentence summary of this incident for the owner.
''';
    return _generateResponse(prompt);
  }

  Future<String?> analyzeLocation(Incident incident, Asset asset) async {
    final prompt = '''
Location Analysis Request:
- Asset: ${asset.name} (${asset.category.displayName})
- Last Known Location: ${asset.address}
- Coordinates: ${asset.latitude.toStringAsFixed(6)}° N, ${asset.longitude.toStringAsFixed(6)}° E
- Last Detection: ${asset.lastPing.toIso8601String()}
- Location History Points: ${asset.locationHistory.length} points

Recent Detections:
${asset.locationHistory.reversed.take(5).map((p) => '- ${p.timestamp.toIso8601String()}: ${p.latitude.toStringAsFixed(4)}° N, ${p.longitude.toStringAsFixed(4)}° E').join('\n')}

Incident Timeline:
${incident.timeline.map((t) => '- ${t.timestamp.toIso8601String()}: ${t.title}').join('\n')}

Analyze the location pattern and provide 2-3 sentences of actionable insight for recovery.
''';
    return _generateResponse(prompt);
  }

  Future<String?> generateRecoveryGuidance(Incident incident, Asset asset) async {
    final timeSinceLastPing = DateTime.now().difference(asset.lastPing);
    final timeSinceIncident = DateTime.now().difference(incident.timestamp);

    final prompt = '''
Recovery Guidance Request:
- Asset: ${asset.name} (${asset.category.displayName})
- Status: ${asset.status.displayName}
- Time Since Incident: ${_formatDuration(timeSinceIncident)}
- Time Since Last Detection: ${_formatDuration(timeSinceLastPing)}
- Last Known Area: ${asset.address}
- Incident Type: ${incident.type}

Current Situation: ${incident.status == 'Tracking' ? 'Active tracking in progress' : 'Tracking concluded'}

Provide 3-4 specific, actionable recovery steps the owner should take right now.
''';
    return _generateResponse(prompt);
  }

  Future<String?> generateIncidentReport(Incident incident, Asset asset) async {
    final prompt = '''
Generate a concise formal incident report for campus security/authorities:

Asset: ${asset.name}
Identifier: ${asset.identifier}
Category: ${asset.category.displayName}
Incident ID: ${incident.id}
Type: ${incident.type}
Status: ${incident.status}
Reported: ${incident.timestamp.toIso8601String()}
Last Location: ${asset.address}
Coordinates: ${asset.latitude.toStringAsFixed(6)}° N, ${asset.longitude.toStringAsFixed(6)}° E

Timeline:
${incident.timeline.map((t) => '${t.timestamp.toIso8601String()}: ${t.title} - ${t.description}').join('\n')}

Description: ${incident.description}

Format as a professional incident report (bullet points, clear sections).
''';
    return _generateResponse(prompt);
  }

  Future<String?> answerQuestion(Incident incident, Asset asset, String question) async {
    final prompt = '''
User Question: "$question"

Context:
- Asset: ${asset.name} (${asset.identifier}, ${asset.category.displayName})
- Status: ${asset.status.displayName}
- Last Location: ${asset.address} (${asset.latitude.toStringAsFixed(4)}° N, ${asset.longitude.toStringAsFixed(4)}° E)
- Last Detection: ${asset.lastPing.toIso8601String()}
- Incident: ${incident.id} (${incident.type}, ${incident.status})
- Incident Time: ${incident.timestamp.toIso8601String()}
- Description: ${incident.description}

Recent Timeline:
${incident.timeline.map((t) => '- ${t.timestamp.toIso8601String()}: ${t.title} - ${t.description}').join('\n')}

Location History (last 5):
${asset.locationHistory.reversed.take(5).map((p) => '- ${p.timestamp.toIso8601String()}: ${p.latitude.toStringAsFixed(4)}° N, ${p.longitude.toStringAsFixed(4)}° E').join('\n')}

Answer the user's question based ONLY on the above context. Be concise (2-3 sentences). If the answer isn't in the context, say so.
''';
    return _generateResponse(prompt);
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  void dispose() {
    _model = null;
    _isInitialized = false;
  }
}