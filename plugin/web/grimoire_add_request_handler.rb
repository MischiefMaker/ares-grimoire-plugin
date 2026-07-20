# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireAddRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        # Check staff permission
        unless GrimoireApi.can_manage?(enactor)
          return { error: t('grimoire.staff_only') }
        end

        request.log_request

        result = GrimoireApi.create_spell(
          branch_key: request.args['branch_key'],
          name: request.args['name'],
          description: request.args['description'],
          minimum_skill: request.args['minimum_skill'].to_i,
          difficulty: request.args['difficulty'].to_i,
          created_by: enactor,
          approved: true
        )

        if result[:success]
          { success: true, spell: GrimoireApi.spell_json(result[:spell]) }
        else
          { error: result[:errors].join(', ') }
        end
      end
    end
  end
end
