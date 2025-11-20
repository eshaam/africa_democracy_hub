class PetitionGenerationJob < ApplicationJob
  queue_as :default

  # Updated to accept base_url (e.g. "https://xxxx.ngrok.io")
  def perform(petition_id, base_url = "https://democracyhub.org")
    petition = Petition.find(petition_id)
    petition.update(status: 'processing')

    client = GeminiService.new
    generated_text = client.draft_petition(petition.raw_input, petition.topic)

    petition.update(final_content: generated_text, status: 'completed')

    send_telegram_reply(petition, generated_text, base_url)
  rescue StandardError => e
    Rails.logger.error("Job Failed: #{e.message}")
    petition.update(status: 'failed')
    send_error(petition.telegram_chat_id, e.message)
  end

  private

  def send_telegram_reply(petition, text, base_url)
    token = Rails.application.credentials.dig(:telegram, :bot_token)
    
    # Construct the correct URL using the passed base_url
    petition_url = "#{base_url}/petitions/#{petition.id}"
    Rails.logger.info "Generated Public URL: #{petition_url}"

    Telegram::Bot::Client.run(token) do |bot|
      # Send text in chunks
      text.chars.each_slice(4000) { |chunk| bot.api.send_message(chat_id: petition.telegram_chat_id, text: chunk.join) }
      
      # Send Link Button
      kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: '🌐 View & Print Petition', url: petition_url)]]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      
      bot.api.send_message(chat_id: petition.telegram_chat_id, text: "✅ **Petition Ready!**", reply_markup: markup)
    end
  end
  
  def send_error(chat_id, msg)
    token = Rails.application.credentials.dig(:telegram, :bot_token)
    Telegram::Bot::Client.run(token) do |bot| 
      bot.api.send_message(chat_id: chat_id, text: "Error: #{msg}") 
    end
  end
end