# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireLearnRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        spell_id = request.args['spell_id']
        result = GrimoireApi.learn_spell(enactor, spell_id.to_i)
        result[:success] ? { success: true, message: result[:message] } : { error: result[:message] }
      end
    end
  end
end
