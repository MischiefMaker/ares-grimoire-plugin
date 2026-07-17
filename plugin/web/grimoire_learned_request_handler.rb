# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireLearnedRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        { spells: GrimoireService.learned_spells(enactor).map { |s| GrimoireService.spell_json(s) } }
      end
    end
  end
end
