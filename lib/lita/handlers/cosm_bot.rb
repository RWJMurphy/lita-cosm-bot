module Lita
  module Handlers
    class CosmBot < Handler
      route(/^\s*(.*)\s*\?$/, :answer, command: true, help: { "some question?" => "answers questions" })
      def answer(response)
        thing = response.match_data[1]
        definition = redis.get(thing)
        if definition.nil?
          response.reply "I'm not sure, #{response.user.name}."
        else
          response.reply definition
        end
      end

      route(/^remember\s+.+\s+is\s+[^\s]+/i, :remember, command: true, help: { "remember X is Y" => "remembers a thing" })
      def remember(response)
        thing = response.args[0]
        definition = response.args[2..-1].join(" ")
        if redis.get(thing).nil?
          redis.set(thing, definition)
          response.reply("Ok #{response.user.name}, #{thing} is #{definition}.")
        else
          response.reply("Sorry #{response.user.name}, #{thing} is #{redis.get(thing)}.")
        end
      end

      route(/^forget\s+[^\s]+/, :forget, command: true, help: { "forget X" => "forget a thing" })
      def forget(response)
        thing = response.args[0]
        if redis.get(thing).nil?
          response.reply("Sorry #{response.user.name}, I don't know about #{thing}.")
        else
          redis.del(thing)
          response.reply("Ok #{response.user.name}, I've forgotten #{thing}.")
        end
      end

      route(/^(,\s+)?reveal\s+your\s+secrets!/i, :dump, command: true)
      def dump(response)
        m = redis.keys('*')
            .sort
            .map { |key| [k, redis.get(key)] }
            .map { |pair| pair.join ": " }
            .join("\n")
        response.reply(m)
      end
    end

    Lita.register_handler(CosmBot)
  end
end
