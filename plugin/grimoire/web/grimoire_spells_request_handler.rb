# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireSpellsRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        { spells: GrimoireService.castable_spells(enactor).map { |s| GrimoireService.spell_json(s) } }
      end
    end
  end
end
