#!/usr/bin/env ruby

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "sid_list"


class List < SidList

	def update_hash time
		hash = {:updated => [{:id => 3, :name=>'meou'}]}
		return hash
	end
end

class Job
	attr_accessor :id, :name, :status, :date
	
	def initialize values={}
		@id = values[:id]
		@name = values[:name]
		@status = values[:status]
		@date = values[:date]
	end
end

jobs = List.new

jobs.add Job.new :id => 1, :name => 'aaa', :status => :new, :date => '2013-03-25 16:24:58'
jobs.add Job.new :id => 2, :name => 'bbb', :status => :new, :date => '2013-03-25 16:24:58'
jobs.add Job.new :id => 3, :name => 'ccc', :status => :old, :date => '2013-03-25 16:24:58'
jobs.add Job.new :id => 4, :name => 'aaa', :status => :old, :date => '2013-03-25 16:24:58'
jobs.add Job.new :id => 5, :name => 'bbb', :status => :new, :date => '2013-03-25 16:24:58'

# puts "found: #{jobs.find :name => 'aaa', :id => 3}"
# puts jobs.list_by_status.inspect

# puts jobs.find(:name => 'aaa', :status => :new).inspect
# jobs.change_status(1, :old)
# puts jobs.list_by_status.inspect

puts jobs.update
puts jobs.find(3).inspect
puts jobs.old