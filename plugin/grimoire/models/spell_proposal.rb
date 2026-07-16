# frozen_string_literal: true

module AresMUSH
  class SpellProposal < Ohm::Model
    include ObjectModel

    attribute :job_id
    attribute :branch_key
    attribute :name
    attribute :description
    attribute :minimum_skill, :type => DataType::Integer, :default => 0
    attribute :difficulty, :type => DataType::Integer, :default => 0

    reference :proposed_by, "AresMUSH::Character"

    index :job_id
    index :branch_key
  end
end
