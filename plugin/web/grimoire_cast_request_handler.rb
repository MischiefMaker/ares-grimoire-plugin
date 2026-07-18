# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireCastRequestHandler
      def handle(request)
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error

        request.log_request

        spell_id = request.args['spell_id']
        scene_id = request.args['scene_id']
        spell = GrimoireApi.find_spell(spell_id.to_i)
        return { error: t('grimoire.spell_not_found', id: spell_id) } unless spell

        show_details = Global.read_config('grimoire', 'casting', 'show_roll_details')
        result = GrimoireApi.cast_spell(enactor, spell,
          scene_id: scene_id,
          show_details: show_details)
        result[:success] ? { success: true, message: result[:message] } : { error: result[:message] }
      end
    end
  end
end
