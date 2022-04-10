# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  # Activate the gem you are reporting the issue against.
  gem "activerecord", ENV.fetch('RAILS_VERSION',  "~> 7.0.0")
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
  end

  create_table :comments, force: true do |t|
    t.belongs_to :target, polymorphic: true
  end
end

class Post < ActiveRecord::Base
  has_many :comments, as: :target
end

class Comment < ActiveRecord::Base
  belongs_to :target, polymorphic: true
end

class BugTest < Minitest::Test
  def test_strict_loading_to_polymofic_model
    post = Post.create!
    Comment.create!(target: post)
    comment = Comment.last
    comment.strict_loading!
    error = assert_raises(ArgumentError) { comment.target }
    assert_equal error.message, 'Polymorphic associations do not support computing the class.'
  end
end
