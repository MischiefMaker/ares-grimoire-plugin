# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireLearnedRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        { spells: GrimoireApi.learned_spells(enactor).map { |s| GrimoireApi.spell_json(s) } }
      end
    end
  end
end
