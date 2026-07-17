# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireAddRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        # Check staff permission
        unless enactor.is_admin? || enactor.has_permission?('manage_grimoire')
          return { error: "Insufficient permissions to manage spells." }
        end

        request.log_request

        result = GrimoireService.create_spell(
          branch_key: request.args['branch_key'],
          name: request.args['name'],
          description: request.args['description'],
          minimum_skill: request.args['minimum_skill'].to_i,
          difficulty: request.args['difficulty'].to_i,
          created_by: enactor,
          approved: true
        )

        if result[:success]
          { success: true, spell: GrimoireService.spell_json(result[:spell]) }
        else
          { error: result[:errors].join(', ') }
        end
      end
    end
  end
end
