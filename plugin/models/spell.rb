# frozen_string_literal: true

module AresMUSH
  class Spell < Ohm::Model
    include ObjectModel

    attribute :branch_key
    attribute :name
    attribute :description
    attribute :minimum_skill, :type => DataType::Integer, :default => 0
    attribute :difficulty, :type => DataType::Integer, :default => 0
    attribute :approved, :type => DataType::Boolean, :default => false

    reference :created_by, "AresMUSH::Character"

    index :branch_key
    index :name

    before_delete :delete_learned_records

    def delete_learned_records
      CharacterSpellLearned.find(spell_id: self.id).each { |l| l.delete }
    end
  end
end
