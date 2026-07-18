# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireLearnCmd
      include CommandHandler

      attr_accessor :spell_id

      def parse_args
        self.spell_id = trim_arg(cmd.args)
      end

      def required_args
        [ self.spell_id ]
      end

      def handle
        result = GrimoireApi.learn_spell(enactor, self.spell_id)
        if result[:success]
          client.emit_success result[:message]
        else
          client.emit_failure result[:message]
        end
      end
    end
  end
end
