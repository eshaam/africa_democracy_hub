class RumorAnalysisJob < ApplicationJob
  queue_as :default

  def perform(rumor_id)
    rumor = Rumor.find(rumor_id)
    
    # 1. Call Gemini (using the method we defined in Step 1)
    client = GeminiService.new
    raw_json_string = client.analyze_rumor(rumor.content)
    
    # 2. Parse JSON
    begin
      analysis = JSON.parse(raw_json_string)
      
      # 3. Update Database
      rumor.update(
        status: 'analyzed',
        danger_level: analysis['danger_level'],
        sentiment: analysis['sentiment'],
        ai_summary: analysis['analysis'],
        raw_ai_response: analysis
      )
      
      # 4. Reply to User
      send_verdict(rumor)
      
    rescue JSON::ParserError => e
      # Fallback if AI returns bad JSON
      rumor.update(status: 'failed', raw_ai_response: { error: e.message })
      send_error(rumor.user.telegram_chat_id)
    end
  end

  private

  def send_verdict(rumor)
    token = Rails.application.credentials.dig(:telegram, :bot_token)
    Telegram::Bot::Client.run(token) do |bot|
      
      icon = case rumor.danger_level
             when 'High' then 'RED ALERT 🚨'
             when 'Medium' then '⚠️ Caution'
             else '✅ Likely Safe'
             end

      response_text = <<~TEXT
        **VeriStream Analysis** #{icon}
        
        **Danger Level:** #{rumor.danger_level}
        **Sentiment:** #{rumor.sentiment}
        
        **AI Assessment:**
        #{rumor.ai_summary}
        
        _Note: This is an automated check. A human researcher will review this shortly._
      TEXT
      
      bot.api.send_message(chat_id: rumor.user.telegram_chat_id, text: response_text, parse_mode: 'Markdown')
    end
  end

  def send_error(chat_id)
    token = Rails.application.credentials.dig(:telegram, :bot_token)
    Telegram::Bot::Client.run(token) do |bot|
      bot.api.send_message(chat_id: chat_id, text: "⚠️ Our AI had trouble analyzing that message. It has been flagged for human review.")
    end
  end
end