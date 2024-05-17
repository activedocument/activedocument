# frozen_string_literal: true

require 'spec_helper'

describe Dynamoid::Associations::HasMany do
  let(:magazine) { Magazine.create }
  let(:user) { User.create }
  let(:camel_case) { CamelCase.create }

  it 'determines equality from its records' do
    subscription = magazine.subscriptions.create

    expect(magazine.subscriptions).to eq subscription
  end

  it 'determines target association correctly' do
    expect(magazine.subscriptions.send(:target_association)).to eq :magazine
    expect(user.books.send(:target_association)).to eq :owner
    expect(camel_case.users.send(:target_association)).to eq :camel_case
  end

  it 'determins target class correctly' do
    expect(magazine.subscriptions.send(:target_class)).to eq Subscription
    expect(user.books.send(:target_class)).to eq Magazine
  end

  it 'determines target attribute' do
    expect(magazine.subscriptions.send(:target_attribute)).to eq :magazine_ids
    expect(user.books.send(:target_attribute)).to eq :owner_ids
  end

  it 'associates belongs_to automatically' do
    subscription = magazine.subscriptions.create

    expect(subscription.magazine).to eq magazine

    magazine = user.books.create
    expect(magazine.owner).to eq user
  end

  it 'has a where method to filter associates' do
    red = magazine.camel_cases.create
    red.color = 'red'
    red.save

    blue = magazine.camel_cases.create
    blue.color = 'blue'
    blue.save

    expect(magazine.camel_cases.count).to eq 2
    expect(magazine.camel_cases.where(color: 'red').count).to eq 1
  end

  it 'is not modified by the where method' do
    red = magazine.camel_cases.create
    red.color = 'red'
    red.save

    blue = magazine.camel_cases.create
    blue.color = 'blue'
    blue.save

    expect(magazine.camel_cases.where(color: 'red').count).to eq 1
    expect(magazine.camel_cases.where(color: 'yellow').count).to eq 0
    expect(magazine.camel_cases.count).to eq 2
  end

  describe 'assigning' do
    let(:magazine) { Magazine.create }
    let(:subscription) { Subscription.create }

    it 'associates model on this side' do
      magazine.subscriptions << subscription
      expect(magazine.subscriptions.to_a).to eq([subscription])
    end

    it 'associates model on that side' do
      magazine.subscriptions << subscription
      expect(subscription.magazine).to eq(magazine)
    end

    it 're-associates new model on this side' do
      magazine_old = Magazine.create
      magazine_new = Magazine.create
      magazine_old.subscriptions << subscription

      expect do
        magazine_new.subscriptions << subscription
      end.to change { magazine_new.subscriptions.to_a }.from([]).to([subscription])
    end

    it 're-associates new model on that side' do
      magazine_old = Magazine.create
      magazine_new = Magazine.create
      magazine_old.subscriptions << subscription

      expect do
        magazine_new.subscriptions << subscription
      end.to change { subscription.magazine.target }.from(magazine_old).to(magazine_new)
    end

    it 'deletes previous model from association' do
      magazine_old = Magazine.create
      magazine_new = Magazine.create
      magazine_old.subscriptions << subscription

      expect do
        magazine_new.subscriptions << subscription
      end.to change { Magazine.find(magazine_old.title).subscriptions.to_a }.from([subscription]).to([])
    end
  end

  describe '#delete' do
    it 'clears association on this side' do
      magazine = Magazine.create
      subscription = magazine.subscriptions.create

      expect do
        magazine.subscriptions.delete(subscription)
      end.to change { magazine.subscriptions.target }.from([subscription]).to([])
    end

    it 'persists changes on this side' do
      magazine = Magazine.create
      subscription = magazine.subscriptions.create

      expect do
        magazine.subscriptions.delete(subscription)
      end.to change { Magazine.find(magazine.title).subscriptions.target }.from([subscription]).to([])
    end

    context 'belongs to' do
      let(:magazine) { Magazine.create }
      let!(:subscription) { magazine.subscriptions.create }

      it 'clears association on that side' do
        expect do
          magazine.subscriptions.delete(subscription)
        end.to change { magazine.subscriptions.target }.from([subscription]).to([])
      end

      it 'persists changes on that side' do
        expect do
          magazine.subscriptions.delete(subscription)
        end.to change { Magazine.find(magazine.title).subscriptions.target }.from([subscription]).to([])
      end
    end
  end
end
