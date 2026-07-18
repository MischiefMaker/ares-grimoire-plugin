# frozen_string_literal: true

module AresMUSH
  module Grimoire
    class GrimoireCastCmd
      include CommandHandler

      attr_accessor :spell_id

      def parse_args
        self.spell_id = trim_arg(cmd.args)
      end

      def required_args
        [ self.spell_id ]
      end

      def handle
        spell = GrimoireApi.find_spell(self.spell_id)
        unless spell
          client.emit_failure t('grimoire.spell_not_found', id: self.spell_id)
          return
        end
        show_details = Global.read_config('grimoire', 'casting', 'show_roll_details')
        result = GrimoireApi.cast_spell(enactor, spell, show_details: show_details)
        if result[:success]
          # Emit to room and log to scene, following the FS3 emit_results pattern
          enactor_room.emit result[:message]
          if enactor_room.scene
            Scenes.add_to_scene(enactor_room.scene, result[:message], enactor)
          end
        else
          client.emit_failure result[:message]
        end
      end
    end
  end
end
