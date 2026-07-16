# frozen_string_literal: true

module AresMUSH
  class CharacterSpellLearned < Ohm::Model
    include ObjectModel

    reference :character, "AresMUSH::Character"
    reference :spell, "AresMUSH::Spell"

    attribute :xp_cost, :type => DataType::Integer, :default => 0

    index :character_id
    index :spell_id
  end
end
