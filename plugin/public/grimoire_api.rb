# frozen_string_literal: true

module AresMUSH
  module Grimoire
    def self.learned_spells(char)
      GrimoireService.learned_spells(char)
    end

    def self.castable_spells(char)
      GrimoireService.castable_spells(char)
    end

    def self.has_learned_spell?(char, spell_id)
      GrimoireService.has_learned_spell?(char, spell_id)
    end

    def self.find_spell(id)
      GrimoireService.find_spell(id)
    end
  end
end
