require 'faraday'
require 'json'

class GeminiService
 BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

  def initialize
    @api_key = Rails.application.credentials.dig(:google, :api_key)
  end

  def generate_content(prompt)
    return "Error: API Key missing." unless @api_key

    response = connection.post do |req|
      req.params['key'] = @api_key
      req.headers['Content-Type'] = 'application/json'
      req.body = { contents: [{ parts: [{ text: prompt }] }] }.to_json
    end

    parse_response(response)
  end

  # 1. CivicScribe
  def draft_petition(user_input, topic)
    prompt = "Role: Activist. Task: Write formal petition. Topic: #{topic}. Input: #{user_input}. Max 300 words."
    generate_content(prompt)
  end

  # 2. VeriStream
  def analyze_rumor(rumor_text)
    prompt = <<~PROMPT
      Analyze WhatsApp rumor: "#{rumor_text}"
      Return RAW JSON: {"sentiment": "...", "danger_level": "Low/Medium/High", "analysis": "..."}
    PROMPT
    result = generate_content(prompt)
    result.gsub('```json', '').gsub('```', '').strip
  end

  # 3. TownHall
  def summarize_document(doc_text)
    safe_text = doc_text[0..15000]
    prompt = <<~PROMPT
      Summarize this government document: "#{safe_text}..."
      Output: Title, Budget, Deadlines, 3 Bullet Summary.
    PROMPT
    generate_content(prompt)
  end

  private

  def connection
    Faraday.new(url: BASE_URL) { |f| f.request :retry; f.adapter Faraday.default_adapter }
  end

  def parse_response(response)
    if response.success?
      JSON.parse(response.body).dig('candidates', 0, 'content', 'parts', 0, 'text') || "No content."
    else
      Rails.logger.error("Gemini Error: #{response.body}")
      "System Error: #{response.status} - #{JSON.parse(response.body)['error']['message'] rescue 'Unknown'}"
    end
  end
end