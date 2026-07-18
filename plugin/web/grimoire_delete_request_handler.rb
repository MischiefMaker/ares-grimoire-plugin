# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireDeleteRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        # Check staff permission
        unless GrimoireApi.can_manage?(enactor)
          return { error: "Insufficient permissions to manage spells." }
        end

        request.log_request

        result = GrimoireApi.delete_spell(request.args['spell_id'])

        if result[:success]
          { success: true }
        else
          { error: result[:message] }
        end
      end
    end
  end
end
