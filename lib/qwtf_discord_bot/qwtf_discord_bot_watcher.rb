class QwtfDiscordBotWatcher < QwtfDiscordBot
  THIRTY_SECONDS = 30
  TEN_MINUTES = 10 * 60

  def run
    every(THIRTY_SECONDS) do
      @endpoints.each do |endpoint|
        request = QstatRequest.new(endpoint)

        unless request.is_empty?
          request.player_names.each do |name|
            unless seen_recently?(endpoint: endpoint, name: name)
              report_joined(name: name, server_summary: request.server_summary)
            end

            history[endpoint] ||= {}
            history[endpoint][name] = Time.now
          end
        end
      end
    end
  end

  def every(n_seconds)
    loop do
      before = Time.now
      yield
      interval = n_seconds - (Time.now - before)
      sleep(interval) if interval > 0
    end
  end

  def seen_recently?(endpoint:, name:)
    last_seen = history[endpoint] && history[endpoint][name]
    last_seen && (Time.now - last_seen < TEN_MINUTES)
  end

  def report_joined(name:, server_summary:)
    Discordrb::API::Channel.create_message(
      "Bot #{TOKEN}",
      CHANNEL_ID,
      "#{name} has joined #{server_summary}"
    )
  end

  def history
    @history ||= {}
  end
end
