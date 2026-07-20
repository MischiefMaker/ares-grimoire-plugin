# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireSpellsRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        { spells: GrimoireApi.castable_spells(enactor).map { |s| GrimoireApi.spell_json(s) } }
      end
    end
  end
end
