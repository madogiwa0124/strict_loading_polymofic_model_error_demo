# strict_loading Polymorphic Model error demo

### Steps to reproduce

After performing `strict_loading!` on a model with polymorphic relationships, loading the related model raises an `ArgumentError`.
However, it seems to me that `ActiveRecord::StrictLoadingViolationError` should be raised.

```ruby
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
  def test_strict_loading_to_Polymorphic_model
    post = Post.create!
    Comment.create!(target: post)
    comment = Comment.last
    comment.strict_loading!
    error = assert_raises(ArgumentError) { comment.target }
    assert_equal error.message, 'Polymorphic associations do not support computing the class.'
  end
end
```

### Expected behavior

<!-- Tell us what should happen -->

Raise `ActiveRecord::StrictLoadingViolationError`.

### Actual behavior

<!-- Tell us what happens instead -->

Raise `ArgumentError`

```ruby
ArgumentError: Polymorphic associations do not support computing the class.
  activerecord-7.0.2.3/lib/active_record/reflection.rb:417:in `compute_class'
  activerecord-7.0.2.3/lib/active_record/reflection.rb:376:in `klass'
  activerecord-7.0.2.3/lib/active_record/core.rb:241:in `strict_loading_violation!'
  activerecord-7.0.2.3/lib/active_record/associations/association.rb:220:in `find_target'
  activerecord-7.0.2.3/lib/active_record/associations/singular_association.rb:44:in `find_target'
  activerecord-7.0.2.3/lib/active_record/associations/association.rb:173:in `load_target'
  activerecord-7.0.2.3/lib/active_record/associations/association.rb:67:in `reload'
  activerecord-7.0.2.3/lib/active_record/associations/singular_association.rb:11:in `reader'
  activerecord-7.0.2.3/lib/active_record/associations/builder/association.rb:104:in `target'
  active_record_gem.rb:46:in `test_strict_loading_to_Polymorphic_model'
```

### System configuration

**Rails version**: 6.1.5. 7.0.2.3
**Ruby version**: 2.7, 3.0, 3.1
