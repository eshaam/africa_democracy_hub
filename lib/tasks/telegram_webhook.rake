namespace :telegram do
    desc 'Set up Telegram webhook'
    task setup_webhook: :environment do
      bot_token = Rails.application.credentials.dig(:telegram, :bot_token)
      webhook_secret = Rails.application.credentials.dig(:telegram, :webhook_secret) || SecureRandom.hex(32)

      unless bot_token
        puts 'Telegram bot token not found in credentials.'
        exit
      end
#   curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/setWebhook" \
# -d "url=https://yourdomain.com/telegram/webhook/$TELEGRAM_WEBHOOK_SECRET"
  
      if Rails.env.development?
        webhook_url = "https://marine-supersaturated-natantly.ngrok-free.dev/telegram/receive/#{webhook_secret}"
  
      else
        webhook_url = "https://africa-democracy-hub.eshaam.co.za/telegram/receive/#{webhook_secret}"
  
      end
      # Generate webhook URL with secret token
      
      puts "Setting up Telegram webhook..."
      puts "Webhook URL: #{webhook_url}"
  
      # Set webhook using Telegram Bot API
      response = HTTParty.post(
        "https://api.telegram.org/bot#{bot_token}/setWebhook",
        headers: { 'Content-Type' => 'application/json' },
        body: {
          url: webhook_url,
          allowed_updates: ['message', 'callback_query'],
          secret_token: webhook_secret
        }.to_json
      )
  
      if response.success?
        result = JSON.parse(response.body)
        if result['ok']
          puts "✅ Webhook set successfully!"
          puts "Description: #{result['description']}"
          
          # Store webhook secret in credentials if not already there
          unless Rails.application.credentials.dig(:telegram, :webhook_secret)
            puts "\n⚠️  Add this to your Rails credentials:"
            puts "telegram:"
            puts "  webhook_secret: #{webhook_secret}"
          end
        else
          puts "❌ Failed to set webhook: #{result['description']}"
        end
      else
        puts "❌ HTTP Error: #{response.code} - #{response.body}"
      end
    end

end