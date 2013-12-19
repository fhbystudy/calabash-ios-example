require 'rubygems'
require 'irb/completion'
require 'irb/ext/save-history'
require 'awesome_print'
AwesomePrint.irb!

ARGV.concat [ '--readline', '--prompt-mode', 'simple']

# 25 entries in the list
IRB.conf[:SAVE_HISTORY] = 50

# Store results in home directory with specified file name
IRB.conf[:HISTORY_FILE] = '.irb-history'

require 'calabash-cucumber/operations'
extend Calabash::Cucumber::Operations

require 'calabash-cucumber/launch/simulator_helper'
SIM=Calabash::Cucumber::SimulatorHelper

require 'calabash-cucumber/launcher'


def embed(x,y=nil,z=nil)
   puts "Screenshot at #{x}"
end


@ai=:accessibilityIdentifier
@al=:accessibilityLabel

def print_marks(marks, max_width)
  counter = -1
  marks.sort.each { |elm|
    printf("%4s %#{max_width + 2}s => %s\n", "[#{counter = counter + 1}]", elm[0], elm[1])
  }
end

def accessibility_marks(kind, opts={})
  opts = {:print => true, :return => false}.merge(opts)

  kinds = [:id, :label]
  raise "'#{kind}' is not one of '#{kinds}'" unless kinds.include?(kind)

  res = Array.new
  max_width = 0
  query('*').each { |view|
    aid = view[kind.to_s]
    unless aid.nil? or aid.eql?('')
      cls = view['class']
      len = cls.length
      max_width = len if len > max_width
      res << [cls, aid]
    end
  }
  print_marks(res, max_width) if opts[:print]
  opts[:return] ? res : nil
end

def text_marks(opts={})
  opts = {:print => true, :return => false}.merge(opts)

  indexes = Array.new
  idx = 0
  all_texts = query('*', :text)
  all_texts.each { |view|
    indexes << idx unless view.eql?('*****') or view.eql?('')
    idx = idx + 1
  }

  res = Array.new

  all_views = query('*')
  max_width = 0
  indexes.each { |idx|
    view = all_views[idx]
    cls = view['class']
    text = all_texts[idx]
    len = cls.length
    max_width = len if len > max_width
    res << [cls, text]
  }

  print_marks(res, max_width) if opts[:print]
  opts[:return] ? res : nil
end


def ids
  accessibility_marks(:id)
end

def labels
  accessibility_marks(:label)
end

def text
  text_marks
end

def marks
  opts = {:print => false, :return => true }
  res = accessibility_marks(:id, opts).each { |elm|elm << :ai }
  res.concat(accessibility_marks(:label, opts).each { |elm| elm << :al })
  res.concat(text_marks(opts).each { |elm| elm << :text })
  max_width = 0
  res.each { |elm|
    len = elm[0].length
    max_width = len if len > max_width
  }

  counter = -1
  res.sort.each { |elm|
    printf("%4s %-4s => %#{max_width}s => %s\n",
           "[#{counter = counter + 1}]",
           elm[2], elm[0], elm[1])
  }
  nil
end


def nbl
  query('navigationButton', :accessibilityLabel)
end

def row_ids
  query('tableViewCell', @ai).compact.sort.each {|x| puts "* #{x}" }
end


puts "loaded #{Dir.pwd}/.irbrc"
puts "DEVICE_ENDPOINT => '#{ENV['DEVICE_ENDPOINT']}'"
puts "  DEVICE_TARGET => '#{ENV['DEVICE_TARGET']}'"
puts "         DEVICE => '#{ENV['DEVICE']}'"
puts "      BUNDLE_ID => '#{ENV['BUNDLE_ID']}'"
puts "    SDK_VERSION => '#{ENV['SDK_VERSION']}'"
puts "   PLAYBACK_DIR => '#{ENV['PLAYBACK_DIR']}'"
puts "SCREENSHOT_PATH => '#{ENV['SCREENSHOT_PATH']}'"

puts '*** useful functions defined in .irbrc ***'
puts '> ids     => all accessibilityIdentifiers'
puts '> labels  => all accessibilityLabels'
puts "> text    => all views that respond to the 'text' selector"
puts "> marks   => all visible 'marks'"
puts '> nbl     => all navigation bar button item labels'
puts '> row_ids => all tableViewCell ids'
puts ''
motd=["Let's get this done!", 'Ready to rumble.', 'Enjoy.', 'Remember to breathe.',
      'Take a deep breath.', "Isn't it time for a break?", 'Can I get you a coffee?',
      'What is a calabash anyway?', 'Smile! You are on camera!', 'Let op! Wild Rooster!',
      "Don't touch that button!", "I'm gonna take this to 11.", 'Console. Engaged.',
      'Your wish is my command.', 'This console session was created just for you.']
puts "#{motd.sample}"
