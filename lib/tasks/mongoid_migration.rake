# frozen_string_literal: true

namespace :active_document do
  desc 'Analyze codebase for Mongoid patterns that need migration to ActiveDocument'
  task :analyze_migration, [:path] do |_t, args|
    path = args[:path] || 'app/models'
    puts "Analyzing #{path} for Mongoid migration issues..."
    puts '=' * 60
    puts

    issues = []
    suggestions = []

    Dir.glob("#{path}/**/*.rb").each do |file|
      content = File.read(file)
      lines = content.lines

      lines.each_with_index do |line, idx|
        line_num = idx + 1

        # Check for autosave: false - should be removed (no-op)
        if line =~ /,\s*autosave:\s*false/
          suggestions << {
            file: file,
            line: line_num,
            type: :autosave_false,
            content: line.strip,
            message: 'REMOVE: autosave: false - autosave is no longer supported for referenced associations'
          }
        end

        # Check for autosave: true - alert (removed functionality)
        if line =~ /,\s*autosave:\s*true/
          issues << {
            file: file,
            line: line_num,
            type: :autosave_true,
            content: line.strip,
            message: 'WARNING: autosave: true - autosave is no longer supported. ' \
                     'Associated documents will NOT be automatically saved. ' \
                     'You must explicitly call .save on associated documents.'
          }
        end

        # Check for has_and_belongs_to_many - deprecated
        if line =~ /has_and_belongs_to_many\s+:(\w+)/
          assoc_name = ::Regexp.last_match(1)

          if line =~ /inverse_of:\s*nil/
            # has_and_belongs_to_many with inverse_of: nil - suggest migration
            suggestions << {
              file: file,
              line: line_num,
              type: :habtm_with_nil_inverse,
              content: line.strip,
              message: "MIGRATE: Change 'has_and_belongs_to_many :#{assoc_name}, inverse_of: nil' " \
                       "to 'belongs_to_many :#{assoc_name}' and consider adding " \
                       "a 'has_many :#{inverse_name(file)}' on the inverse class"
            }
          else
            # has_and_belongs_to_many without inverse_of: nil - bidirectional BTM removed
            issues << {
              file: file,
              line: line_num,
              type: :habtm_bidirectional,
              content: line.strip,
              message: "ERROR: Bidirectional has_and_belongs_to_many is no longer supported. " \
                       "You must change one side to belongs_to_many (stores FK) " \
                       "and the other side to has_many (queries via inverse). " \
                       "Add 'inverse_of: nil' temporarily, then refactor."
            }
          end
        end
      end
    end

    # Print issues (errors and warnings)
    if issues.any?
      puts 'ISSUES REQUIRING ATTENTION:'
      puts '-' * 60
      issues.each do |issue|
        puts "#{issue[:file]}:#{issue[:line]}"
        puts "  #{issue[:content]}"
        puts "  >> #{issue[:message]}"
        puts
      end
    end

    # Print suggestions
    if suggestions.any?
      puts 'SUGGESTIONS:'
      puts '-' * 60
      suggestions.each do |suggestion|
        puts "#{suggestion[:file]}:#{suggestion[:line]}"
        puts "  #{suggestion[:content]}"
        puts "  >> #{suggestion[:message]}"
        puts
      end
    end

    if issues.empty? && suggestions.empty?
      puts 'No migration issues found!'
    else
      puts '=' * 60
      puts "Summary: #{issues.count} issues, #{suggestions.count} suggestions"
      puts
      puts 'Migration guide:'
      puts '  1. Remove all autosave: false options (they are no-ops now)'
      puts '  2. Review autosave: true usages - you must manually save associated docs'
      puts '  3. For has_and_belongs_to_many associations:'
      puts '     - Choose which side stores the FK (typically the "child" side)'
      puts '     - That side uses belongs_to_many'
      puts '     - The other side uses has_many'
      puts '     - Only the belongs_to_many side has a _ids field'
      puts
    end
  end

  desc 'Auto-fix simple Mongoid migration issues (removes autosave: false)'
  task :auto_fix_migration, [:path] do |_t, args|
    path = args[:path] || 'app/models'
    puts "Auto-fixing simple migration issues in #{path}..."
    puts '=' * 60
    puts

    fixed_count = 0

    Dir.glob("#{path}/**/*.rb").each do |file|
      content = File.read(file)
      original = content.dup

      # Remove autosave: false (it's a no-op)
      content.gsub!(/,\s*autosave:\s*false/, '')

      if content != original
        File.write(file, content)
        puts "Fixed: #{file}"
        fixed_count += 1
      end
    end

    puts
    puts "Fixed #{fixed_count} files."
    puts 'Run rake active_document:analyze_migration to check remaining issues.'
  end

  private

  def inverse_name(file)
    # Try to guess inverse name from filename
    basename = File.basename(file, '.rb')
    basename.pluralize
  rescue StandardError
    'inverse_models'
  end
end
