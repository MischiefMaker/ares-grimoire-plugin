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
          learned: GrimoireApi.learned_spells(enactor).map { |s| GrimoireApi.spell_json(s) },
          available: GrimoireApi.available_spells(enactor).map do |s|
            GrimoireApi.spell_json(s).merge(
              can_learn: GrimoireApi.can_learn_spell?(enactor, s),
              cost: GrimoireApi.calculate_learning_cost(s),
              current_xp: GrimoireApi.fs3_xp(enactor),
              current_skill: GrimoireApi.fs3_rating(enactor, Grimoire.branch_skill(s.branch_key))
            )
          end,
          can_manage: GrimoireApi.can_manage?(enactor)
        }
      end
    end
  end
end
