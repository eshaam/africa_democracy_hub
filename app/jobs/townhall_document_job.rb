require 'open-uri'

class TownhallDocumentJob < ApplicationJob
  queue_as :default

  def perform(document_id, telegram_file_id)
    doc = TownhallDocument.find(document_id)
    doc.update(status: 'processing')

    begin
      # 1. Get File URL from Telegram
      token = Rails.application.credentials.dig(:telegram, :bot_token)
      api = Telegram::Bot::Api.new(token)
      
      file_obj = api.get_file(file_id: telegram_file_id)
      file_path = file_obj.file_path
      
      # Defined variable is 'download_url'
      download_url = "https://api.telegram.org/file/bot#{token}/#{file_path}"

      # 2. Attach to Active Storage
      filename = File.basename(file_path)
      
      # Corrected variable name
      downloaded_file = URI.open(download_url)
      
      doc.file.attach(io: downloaded_file, filename: filename)

      # 3. Extract Text (PDF vs Text)
      extracted_text = ""
      if filename.downcase.end_with?('.pdf')
        reader = PDF::Reader.new(downloaded_file)
        reader.pages.each { |page| extracted_text += page.text }
      else
        # Rewind file pointer if reading again
        downloaded_file.rewind
        extracted_text = downloaded_file.read
      end

      doc.update(extracted_text: extracted_text)

      # 4. AI Analysis
      client = GeminiService.new
      summary = client.summarize_document(extracted_text)

      doc.update(ai_summary: summary, status: 'completed')

      # 5. Reply to User
      send_summary(doc.user.telegram_chat_id, summary)

    rescue StandardError => e
      Rails.logger.error("TownHall Job Failed: #{e.message}")
      doc.update(status: 'failed')
      send_error(doc.user.telegram_chat_id, e.message)
    end
  end

  private

  def send_summary(chat_id, text)
    token = Rails.application.credentials.dig(:telegram, :bot_token)
    Telegram::Bot::Client.run(token) do |bot|
      # Split if too long
      text.chars.each_slice(4000) do |chunk|
        # FIX: Removed parse_mode: 'Markdown'
        # This prevents crashes when the AI outputs underscores (_) or asterisks (*)
        # that don't match Telegram's strict formatting rules.
        bot.api.send_message(chat_id: chat_id, text: chunk.join)
      end
      
      # Send final confirmation
      bot.api.send_message(chat_id: chat_id, text: "✅ Analysis Complete.")
    end
  end

  def send_error(chat_id, error)
    token = Rails.application.credentials.dig(:telegram, :bot_token)
    Telegram::Bot::Client.run(token) do |bot|
      bot.api.send_message(chat_id: chat_id, text: "❌ Failed to process document: #{error}")
    end
  end
end