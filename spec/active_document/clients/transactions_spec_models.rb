# frozen_string_literal: true

class TransactionsSpecCounter
  def initialize
    @called = 0
  end

  def inc
    @called += 1
  end

  def value
    @called
  end

  def reset
    @called = 0
  end
end

module TransactionsSpecCountable
  def after_commit_counter
    @after_commit_counter ||= TransactionsSpecCounter.new
  end

  def after_commit_counter=(new_counter)
    @after_commit_counter = new_counter
  end

  def after_rollback_counter
    @after_rollback_counter ||= TransactionsSpecCounter.new
  end

  def after_rollback_counter=(new_counter)
    @after_rollback_counter = new_counter
  end
end

class TransactionsSpecPerson
  include ActiveDocument::Document
  include TransactionsSpecCountable

  field :name, type: :string

  after_commit do
    after_commit_counter.inc
  end

  after_rollback do
    after_rollback_counter.inc
  end
end

class TransactionsSpecPersonWithOnCreate
  include ActiveDocument::Document
  include TransactionsSpecCountable

  field :name, type: :string

  after_commit on: :create do
    after_commit_counter.inc
  end

  after_rollback on: :create do
    after_rollback_counter.inc
  end
end

class TransactionsSpecPersonWithOnUpdate
  include ActiveDocument::Document
  include TransactionsSpecCountable

  field :name, type: :string

  after_commit on: :update do
    after_commit_counter.inc
  end

  after_rollback on: :update do
    after_rollback_counter.inc
  end
end

class TransactionsSpecPersonWithOnDestroy
  include ActiveDocument::Document
  include TransactionsSpecCountable

  field :name, type: :string

  after_commit on: :destroy do
    after_commit_counter.inc
  end

  after_rollback on: :destroy do
    after_rollback_counter.inc
  end
end

class TransactionSpecRaisesBeforeSave
  include ActiveDocument::Document
  include TransactionsSpecCountable

  field :attr, type: :string

  before_save do
    raise 'I cannot be saved'
  end

  after_commit do
    after_commit_counter.inc
  end

  after_rollback do
    after_rollback_counter.inc
  end
end

class TransactionSpecRaisesAfterSave
  include ActiveDocument::Document
  include TransactionsSpecCountable

  field :attr, type: :string

  after_save do
    raise 'I cannot be saved'
  end

  after_commit do
    after_commit_counter.inc
  end

  after_rollback do
    after_rollback_counter.inc
  end
end

class TransactionSpecRaisesBeforeCreate
  include ActiveDocument::Document

  def self.after_commit_counter
    @@after_commit_counter ||= TransactionsSpecCounter.new
  end

  def self.after_rollback_counter
    @@after_rollback_counter ||= TransactionsSpecCounter.new
  end

  field :attr, type: :string

  before_create do
    raise 'I cannot be saved'
  end

  after_commit do
    self.class.after_commit_counter.inc
  end

  after_rollback do
    self.class.after_rollback_counter.inc
  end
end
