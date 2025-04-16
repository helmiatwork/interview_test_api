# spec/helpers/cached_helper_spec.rb
require 'rails_helper'

RSpec.describe CachedHelper, type: :helper do
  include CachedHelper

  let(:user) { create(:user) } # Assuming a User model and FactoryBot
  let(:cached_set) { Set.new }

  before do
    Rails.cache.clear
  end

  describe '#write_cache' do
    it 'writes the object to the cache' do
      write_cache(user, cached_set)

      cached_user = Rails.cache.read(user.id, namespace: 'user')
      expect(cached_user).to eq(user)
    end

    it 'does not cache the same object twice in one cycle' do
      expect(Rails.cache).to receive(:write).once.and_call_original
      write_cache(user, cached_set)
      write_cache(user, cached_set) # Should be skipped
    end
  end

  describe '#fetch_cache' do
    context 'when cache exists' do
      it 'returns cached object' do
        Rails.cache.write(user.id.to_s, user, namespace: 'user')
        expect(fetch_cache(user.id, klass: User)).to eq(user)
      end
    end

    context 'when cache does not exist' do
      it 'fetches and caches the object from the database' do
        fetched_user = fetch_cache(user.id, klass: User)
        expect(fetched_user).to eq(user)
        expect(Rails.cache.read(user.id.to_s, namespace: 'user')).to eq(user)
      end
    end
  end

  describe '#delete_cache' do
    it 'removes object from cache' do
      Rails.cache.write(user.id, user, namespace: 'user')
      delete_cache(user)
      expect(Rails.cache.read(user.id, namespace: 'user')).to be_nil
    end
  end
end
