# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireAllSpellsRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        # Check staff permission
        unless enactor.is_admin? || enactor.has_permission?('manage_grimoire')
          return { error: "Insufficient permissions." }
        end

        request.log_request

        # Get all spells (both approved and unapproved) for staff view
        spells = Spell.all.to_a.sort_by { |s| s.name.downcase }

        {
          spells: spells.map { |s|
            GrimoireService.spell_json(s).merge(
              approved: s.approved
            )
          }
        }
      end
    end
  end
end
