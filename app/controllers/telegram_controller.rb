require 'telegram/bot'

class TelegramController < ApplicationController
skip_before_action :verify_authenticity_token

  def receive
    token = Rails.application.credentials.dig(:telegram, :bot_token)
    body = JSON.parse(request.body.read)
    update = Telegram::Bot::Types::Update.new(body)
    message = update.message || update.callback_query

    chat_id = message.is_a?(Telegram::Bot::Types::CallbackQuery) ? message.from.id : message.chat.id
    @user = User.find_or_initialize_by(telegram_chat_id: chat_id.to_s)
    
    if @user.new_record?
      @user.email = "#{chat_id}@democracyhub.bot"
      @user.password = Devise.friendly_token[0, 20]
      @user.save!
    end

    if message.respond_to?(:text) && message.text == '/reset'
      @user.update(onboarding_status: 'new', terms_accepted_at: nil, current_step: nil, step_data: {})
      Telegram::Bot::Client.run(token) { |b| b.api.send_message(chat_id: chat_id, text: "🔄 Reset.") }
      head :ok
      return
    end

    Telegram::Bot::Client.run(token) do |bot|
      if @user.onboarded?
        handle_standard_flow(message, bot, chat_id)
      else
        handle_onboarding(message, bot)
      end
    end

    head :ok
  end

  private

  # --- ONBOARDING ---
  def handle_onboarding(message, bot)
    case @user.onboarding_status
    when 'new'
      bot.api.send_message(chat_id: @user.telegram_chat_id, text: "👋 Welcome! What is your **Full Name**?")
      @user.update(onboarding_status: 'waiting_name')
    when 'waiting_name'
      if message.try(:text)
        @user.update(full_name: message.text, onboarding_status: 'waiting_phone')
        kb = [[Telegram::Bot::Types::KeyboardButton.new(text: "📱 Share Phone", request_contact: true)]]
        markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb, one_time_keyboard: true)
        bot.api.send_message(chat_id: @user.telegram_chat_id, text: "Hi #{@user.full_name}! Share your **Phone**.", reply_markup: markup)
      end
    when 'waiting_phone'
      phone = message.try(:contact).try(:phone_number) || message.try(:text)
      if phone
        @user.update(phone_number: phone, onboarding_status: 'waiting_location')
        kb = [[Telegram::Bot::Types::KeyboardButton.new(text: "📍 Share Location", request_location: true)]]
        markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb, one_time_keyboard: true)
        bot.api.send_message(chat_id: @user.telegram_chat_id, text: "Got it. Now share your **Location**.", reply_markup: markup)
      end
    when 'waiting_location'
      if message.try(:location)
        @user.update(latitude: message.location.latitude, longitude: message.location.longitude, onboarding_status: 'waiting_terms')
        @user.safe_reverse_geocode
        kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: "✅ Agree", callback_data: 'agree_terms')]]
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
        bot.api.send_message(chat_id: @user.telegram_chat_id, text: "Located in #{@user.city&.name || 'your area'}. Agree to terms?", reply_markup: markup)
      end
    when 'waiting_terms'
      if message.try(:data) == 'agree_terms'
        @user.update(terms_accepted_at: Time.current, onboarding_status: 'completed')
        bot.api.send_message(chat_id: @user.telegram_chat_id, text: "🎉 Done!", reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true))
        show_main_menu(bot, @user.telegram_chat_id)
      end
    end
  end

  # --- STANDARD FLOW ---
  def handle_standard_flow(message, bot, chat_id)
    if message.is_a?(Telegram::Bot::Types::Message)
      if @user.current_step.present?
        handle_step_logic(message, bot)
      elsif message.text == '/start'
        show_main_menu(bot, chat_id)
      else
        bot.api.send_message(chat_id: chat_id, text: "Use /start for the menu.")
      end
    elsif message.is_a?(Telegram::Bot::Types::CallbackQuery)
      handle_callback(message, bot)
    end
  end

  def handle_callback(callback, bot)
    chat_id = callback.from.id
    case callback.data
    when 'scribe'
      bot.api.send_message(chat_id: chat_id, text: "📝 **CivicScribe**\nWhat is the **Topic**?")
      set_state('scribe_awaiting_topic')
    when 'rumor'
      bot.api.send_message(chat_id: chat_id, text: "🔍 **VeriStream**\nForward a suspicious message.")
      set_state('rumor_awaiting_input')
    when 'townhall'
      bot.api.send_message(chat_id: chat_id, text: "🏛️ **TownHall AI**\n\nPlease upload a **PDF Document**.")
      set_state('townhall_awaiting_file')
    end
  end

  def handle_step_logic(message, bot)
    chat_id = message.chat.id
    text = message.text
    
    case @user.current_step
    
    # 1. Petition
    when 'scribe_awaiting_topic'
      set_state('scribe_awaiting_input', { topic: text })
      bot.api.send_message(chat_id: chat_id, text: "Topic: #{text}. Now describe the details.")
    
    when 'scribe_awaiting_input'
      data = @user.step_data
      petition = Petition.create!(telegram_chat_id: chat_id.to_s, user: @user, topic: data['topic'], raw_input: text)
      
      # UPDATED: Pass request.base_url to the job!
      PetitionGenerationJob.perform_later(petition.id, request.base_url)
      
      bot.api.send_message(chat_id: chat_id, text: "⏳ Writing petition...")
      clear_state

    # 2. Rumor
    when 'rumor_awaiting_input'
      rumor = Rumor.create!(user: @user, country: @user.country, content: text, status: 'pending')
      RumorAnalysisJob.perform_later(rumor.id)
      bot.api.send_message(chat_id: chat_id, text: "🔎 Scanning...")
      clear_state

    # 3. TownHall
    when 'townhall_awaiting_file'
      if message.document
        doc = TownhallDocument.create!(
          user: @user, 
          title: message.document.file_name || "Uploaded Document",
          file_type: message.document.mime_type,
          status: 'pending'
        )
        TownhallDocumentJob.perform_later(doc.id, message.document.file_id)
        bot.api.send_message(chat_id: chat_id, text: "📥 Reading file...")
        clear_state
      else
        bot.api.send_message(chat_id: chat_id, text: "⚠️ Please upload a valid PDF file.")
      end
    end
  end

  def set_state(step, data = {})
    new_data = (@user.step_data || {}).merge(data)
    @user.update(current_step: step, step_data: new_data)
  end

  def clear_state
    @user.update(current_step: nil, step_data: {})
  end

  def show_main_menu(bot, chat_id)
    kb = [
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: '📜 CivicScribe', callback_data: 'scribe')],
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🔍 VeriStream', callback_data: 'rumor')],
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: '🏛️ TownHall', callback_data: 'townhall')]
    ]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
    bot.api.send_message(chat_id: chat_id, text: "Select a tool:", reply_markup: markup)
  end
end