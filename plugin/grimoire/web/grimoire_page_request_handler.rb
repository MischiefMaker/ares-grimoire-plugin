# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoirePageRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        {
          learned: GrimoireService.learned_spells(enactor).map { |s| GrimoireService.spell_json(s) },
          available: GrimoireService.available_spells(enactor).map do |s|
            GrimoireService.spell_json(s).merge(
              can_learn: GrimoireService.can_learn_spell?(enactor, s),
              cost: GrimoireService.calculate_learning_cost(s),
              current_xp: GrimoireService.fs3_xp(enactor),
              current_skill: GrimoireService.fs3_rating(enactor, Grimoire.branch_skill(s.branch_key))
            )
          end
        }
      end
    end
  end
end
