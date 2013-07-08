require "sid_list/version"

class SidList
	# Creates a list of objects (jobs, instances, etc.) indexed by id & status
	attr_accessor :list_by_status, :list_by_id

	def initialize
		@list_by_id = Array.new()
		@list_by_status = Hash.new()
	end

	# Finds objecst in the list based on any of its accessible attributes. 
	# If only a Fixnum is passed, it will be interpreted as an id search.
	# @note the Object must respond to obj#attribute().
	# @return [Array] Objects found.
	#
	# @params values [Hash] Params. for search.
	# @params values [Fixnum] Id.
	def find values={}
		found = Array.new

		if values.is_a? Fixnum
			return @list_by_id[values]
			# values = {:id => values}
		elsif !values.is_a? Hash
			raise ArgumentError, 'argument must be a Hash or a Fixnum.'
		end
			
		@list_by_status.each do |status, status_list|

			status_list.each do |obj|

				# Catch is now acting as an OR condition.
				# Maybe it would be a good idea to do it an AND
				# @todo change this to AND
				catch :not_equal do
					values.each do |term, value|
						if obj.send(term)!= value
							throw :not_equal
						end
					end
					found << obj
				end

			end
		end

		return found
	end

	def add obj
		@list_by_id[obj.id] = obj # Add obj by id

		# Add obj by status. ensure_status_in_list is called to make sure that the status
		#  has an array in @list_by_status.
		ensure_status_in_list(obj.status) << obj 

		return self
	end

	# @overload delete(obj)
	# 	Deletes an object from the list.
	# 	@param [Object] obj Object to be deleted.
	#
	# @overload delete(id)
	# 	Deletes an object from the list using its id.
	# 	@param [Fixnum] id Object's id.
	#
	# @todo revise first part to get an optimum algorithm.
	def delete value
		if value.is_a? Fixnum
			id = value
			obj = @list_by_id[value]
		else
			obj = value
			id = obj.id
			value = nil
		end

		@list_by_id.delete_at(id)
		@list_by_status[obj.status].delete obj

		return self
	end

	# Loads objects into list.
	# Objects must be able to receive data in initialization, i.e. Object.new(:name => '', :id => '', ...)
	def load
		load_objs.each do |obj|
			add obj
		end
	end

	# @todo better time options
	# @todo find a way to move adding here without cycling again
	def update opts={}
		time = opts[:time]? opts[:time] : Time.now.utc
		update_objs time
	end

	# @option opts [Symbol] :noforce
	# @option opts [Symbol] :old_status
	def change_status obj, new_status, opts={}
		if obj.is_a? Fixnum
			id = obj
			obj = self.find(id).first
		end

		# Delete Object from old_status
		# If old_status is given, it's easily done. 
		# Otherwise, the object's status must be check to see if it's not the new one (and supose it's the old one).
		# If the status has already been changed, the Object is looked for in @list_by_status.
		# 
		# In any case, we will proceed to the next method if the Object is not found and deleted.
		#
		# Maybe it would be easier just to delete and re-add the Object, but the status may have already changed.
		
		deleted = nil

		# Using opts[:old_status]
		if opts[:old_status]
			if @list_by_status[:old_status].delete(obj)
				deleted = true
			end
		end

		# Using obj.status
		unless deleted && obj.status == new_status 
			if @list_by_status[obj.status].delete(obj) 
				deleted = true
			end
		end

		# Search through @list_by_status
		unless deleted			
			catch :deleted do
				@list_by_status.each do |status, status_list|
					if status_list.include? obj
						@list_by_status[status].delete obj
						deleted = true
						throw :deleted
					end
				end
			end
		end

		# Force status, avoidable with :noforce
		obj.status = new_status unless obj.status == new_status || opts[:noforce]

		# Only add again if deleted?
		# Maybe should add anyway. Or be strict and just allow adding with #add
		ensure_status_in_list(new_status) << obj if deleted

		# Return nil if it has not been deleted (and therefore, not added).
		return deleted
	end

	private 

	###
	# The following methods must be overwritten to configure the list:
	# load_hash
	# update_hash
	# new_obj
	#

	# @return [Array] data to be loaded into list
	# @note This method must be overwritten to configure the list.
	def load_hash
		raise 'StatusList#load_hash() has not been overwritten to allow data to be loaded into the list.'
		
		return Array.new
	end

	# @return [Hash] values to be updated/added. Please see example to see how this hash should be.
	# @example update_hash's return
	# 	update_hash(now) # => {:created => [{:id => 1, ...}, ...], :updated => [{:id => 10, ...}, ...]}
	# @note This method must be overwritten to configure the list.
	def update_hash time
		raise 'StatusList#update_hash() has not been overwritten to allow data in the list to be updated.'

		return Hash.new
	end

	# @param obj_data [Hash] data to be loaded to the Object.
	# @return [Object] new Object the list is composed of.
	# @note This method must be overwritten to configure the list.
	def new_obj obj_data
		raise 'StatusList#new_obj(obj_data)has not been overwritten to allow new objects to be created.'
	end

	def load_objs
		list_data = load_hash()
		obj_array = Array.new()

		list_data.each do |obj_data|
			obj_array << new_obj(obj_data)
		end

		return obj_array
	end

	# Uses #update_hash to get all objects to be added or edited.
	# @param time [Time] time to pass to update_hash in order to get new changes.
	# @note update_hash must return a Hash with keys :created and :updated (see #update_hash).
	
	def update_objs time
		list_data = update_hash(time)
		created_obj_array = Array.new()
		updated_obj_array = Array.new()

		if list_data[:created]
			list_data[:created].each do |obj_data|
				add new_obj obj_data
			end
		end
		if list_data[:updated]
			list_data[:updated].each do |obj_data|
				edit_obj obj_data
			end
		end
	end

	# Updates/Edits an object that already exists.
	# @note Object must respond to the hash's keys. Otherwise an exception will be raised.
	# @param obj_data [Hash] new values for the object.
	# @return obj [Object] edited Object.
	# @return obj [NilClass] nil if no Object was found to be edited.
	def edit_obj obj_data
		obj = @list_by_id[obj_data[:id]]

		if obj
			obj_data.each do |key,value|
				obj.send("#{key}=", value)
			end
		end

		return obj
	end

	# Returns the list for a given status. If there is no such status in list, it is added 
	# (as a new array). It also defines the method #{status}, that calls all the objects with that status,
	# if it hasn't been already been defined.
	# @note if a status has the same name as any of the methods defined in the class, it wont be overwritten.
	# @param status [Symbol] 
	def ensure_status_in_list status
		unless @list_by_status[status].is_a? Array
			@list_by_status[status] = Array.new
		end
		if !(status.is_a? Symbol || status.is_a?(String))
			raise "Object's status has no name (status #{status} was passed)."
		end
		unless self.respond_to?(status)
			self.class.send(:define_method, status) do 
				@list_by_status[status] 
			end
		end
		return @list_by_status[status]
	end
end