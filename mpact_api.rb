require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require './environments'
# require './initializers'


class String
  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

class Fixnum
  def to_bool
    return true if self == 1
    return false if self == 0
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

class TrueClass
  def to_i; 1; end
  def to_bool; self; end
end

class FalseClass
  def to_i; 0; end
  def to_bool; self; end
end

class NilClass
  def to_bool; false; end
end




# use Rack::MethodOverride

set :method_override, true

set :public_folder, 'public'

class Guide < ActiveRecord::Base
	has_many :entries
end

class Note < ActiveRecord::Base
	belongs_to :entry
end

class Request < ActiveRecord::Base
	belongs_to :entry
end

class Entry < ActiveRecord::Base
	belongs_to :guide
	has_many :requests
	has_many :notes
end

class Op < ActiveRecord::Base
end



before do
	error 401 unless params[:apikey] == "1138"
end


get '/' do
  # 'mpact api'
  erb :readme
end

get '/guides' do
	content_type 'application/json'
	Guide.limit(5).to_json
end

# get '/guides/edit' do
# 	erb :edit_guide
# end


helpers do
	def guides_all
		@guides_all ||= Guide.order('key ASC') || halt(404)
	end

	def guide_entries_all
		@guide_entries_all ||= Entry.where('"entries"."guideKey" = ?', params[:key]).order('entrytype ASC', 'name ASC').select('id,"guideKey",name,image,bio,data,entrytype,location,include') || halt(404)
	end

	def guide_entries
		@guide_entries ||= Entry.order('entrytype ASC, name ASC').where('"entries"."include" = ? AND "entries"."guideKey" = ?', true, params[:key]) || halt(404)
	end

	def entry_requests
		@entry_requests ||= Entry.select('entries.id, "entries"."guideKey", entries.name, entries.image, entries.bio, entries.entrytype, entries.location, array_to_string(array_agg(requests.request), \'|\') as reqs').joins(:requests).where('"entries"."guideKey" = ?', params[:key]).group('entries.id')
	end

	configure :development do
		def entry_requests
			@entry_requests ||= Entry.select("entries.id, 'entries'.'guideKey', entries.name, entries.image, entries.bio, entries.location, entries.entrytype, group_concat(requests.request, \"|\") as reqs").joins(:requests).where('"entries"."guideKey" = ?', params[:key]).group('entries.id')
		end
	end

	def entry_notes
		@entry_notes ||= Note.order('created_at ASC, updated_at ASC').where('"notes"."author" = ? AND "notes"."entry_id" = ?', params[:author], params[:entry]) || halt(404)
	end

	def mission_ops
		@mission_ops ||= Op.order('category ASC, what ASC') || halt(404)
	end

	def mission_ops_edit
		@mission_ops_edit ||= Op.order('id ASC') || halt(404)
	end
end

get '/v2/guide/:key/entrieswithreqs' do
	redirect '/guide/' + params[:key] + '/entrieswithreqs?apikey=' + params[:apikey]
end

get '/guide/:key/entrieswithreqs' do
	content_type 'application/json'

	key = params[:key]

	if key == "refuge"
		sorted = entry_requests.sort_by &:id
	else
		sorted = entry_requests.sort_by &:name
	end

	sorted.to_json
end

# v2 GetEntriesForGuide
get '/v2/guide/:key/entries' do
	content_type 'application/json'

	key = params[:key]

	puts params[:debug]

	debug = params[:debug].to_bool
	puts debug ? "debug is true" : "debug is false"

	if key == "refuge"
		sorted = guide_entries.sort_by &:id
	else

		# if debug == true
		# 	puts "return all"
		# 	sorted = guide_entries_all.select('id,"guideKey",name,image,entrytype')
		# else 
		# 	puts "return subset"
			sorted = guide_entries.select('id,"guideKey",name,image,entrytype')
		# end

	end

	sorted.to_json
end


get '/guide/:key/entries' do
	content_type 'application/json'

	key = params[:key]

	puts params[:debug]

	debug = params[:debug].to_bool
	puts debug ? "debug is true" : "debug is false"

	if key == "refuge"
		sorted = guide_entries.sort_by &:id
	else

		if debug == true
			puts "return all"
			sorted = guide_entries_all.select('id,"guideKey",name,image,entrytype,data')
		else 
			puts "return subset"
			sorted = guide_entries.select('id,"guideKey",name,image,entrytype,data')
		end

	end

	sorted.to_json
end


get '/guide/:key/entries/report' do

	if params[:key] == "gmc"
		erb :gmcreport
	else
		"#{params[:key]} report"
	end

end

# get a single entry by index
get '/guide/:key/entry/:idx/requests' do
	content_type 'application/json'

	theEntry = Entry.find_by_id(params[:idx])
	requests = theEntry.requests || []

	requests.to_json
end

# get a single entry for "today" functionality (per guide)
get '/guide/:key/entries/today' do
	content_type 'application/json'
	
	start_date = Date.new(2014, 7, 21)
	today = Date.today
	diff = (today-start_date).to_i
	idx = diff % guide_entries.length

	#production
	guide_entries[idx-1].to_json

end

get '/guide/:key/entries/today/random' do
	content_type 'application/json'
	
	l = guide_entries.length
	r = Random.new.rand(1..l)

	# puts "random number: " + r

	#production
	guide_entries[r-1].to_json

end



# notes
get '/entry/:entry/notes' do
	content_type 'application/json'
	#params entry, author

	entry_notes.to_json
end

post '/entry/:entry/addnote' do

	entry_idx = params[:entry]
	note_text = params[:text]
	author = params[:author]


	if entry_idx.nil? || author.nil? || note_text.nil? || note_text.empty?
		halt(400)
	else
		lastNote = Note.last
		nextid = lastNote.nil? ? 1 : lastNote.id + 1

		puts nextid

		note = Note.create(id: nextid, text: note_text, author: author, entry_id: entry_idx)

	end

end

post '/note/:id' do
	id = params[:id]
	note = Note.find(id)
	return status 404 if note.nil?

	note.delete
	status 202
end

#end notes processing

#mission ops
# get '/ops/add' do
# 	erb :add_op_form
# end
# get '/ops/edit' do
# 	erb :edit_op_form
# end
# get '/ops/report' do
# 	erb :ops_report
# end
# post '/ops/add' do
# 	puts "add " + params[:description]

# 	op = Op.create(
# 			category: params[:category].to_i,
# 			what: params[:what],
# 			when: params[:when],
# 			where: params[:where],
# 			description: params[:description])

# 	redirect '/ops/add?apikey=1138&added=' + op.id.to_s + '&cat=' + op.category.to_s
# end
# post '/ops/edit' do
# 	puts "edit " + params[:description]

# 	id = params[:id]
# 	Op.update(
# 		id, {
# 			:category => params[:category].to_i,
# 			:what => params[:what],
# 			:when => params[:when],
# 			:where => params[:where],
# 			:description => params[:description]
# 		})

# 	redirect '/ops/edit?apikey=1138&edited=' + id.to_s
# end
get '/ops/:cat' do
	content_type 'application/json'
	mission_ops.where('ops.category = ?', params[:cat].to_s).to_json
end
get '/ops' do
	content_type 'application/json'
	mission_ops.to_json
end
#end mission ops

# get '/guide/:key/addentry' do
# 	erb :add_form
# end

get '/entry/:idx' do
	content_type 'application/json'

	entry = Entry.find_by_id(params[:idx])
	
	return entry.to_json(:include => :requests)
end

# post '/guide/:key/entry' do

# 	entry = nil

# 	name = params[:name]
# 	image = params[:image]
# 	# filename = params[:datafile] if !params[:datafile].nil?
# 	# content = params[:dfcontent]

# 	nextid = Entry.last.id + 1

# 	puts nextid.to_s

# 	if !name.nil?
# 		# puts "do stuff"
# 		entry = Entry.create(id: nextid, guideKey: params[:key], name: name, image: image, entrytype: params[:entrytype])

# 		if !image.nil?
# 			entry.image = image
# 		end

# 		redirect '/guide/' + params[:key] + '/addentry?apikey=1138&added=' + entry.id.to_s + '&et=' + entry.entrytype.to_s
# 	else
# 		redirect '/guide/' + params[:key] + '/addentry?apikey=1138&error=Error adding new entry.'
# 	end

# end

# get '/guide/:key/editentries' do
# 	erb :db_form
# end

# post '/guide/:key/editentry' do

# 	id = params[:entry]

# 	Entry.update(id, { :image => params[:image], :name => params[:name], :entrytype => params[:entrytype], :bio => params[:bio], :location => params[:location], :include => params[:include] })

# 	reqs_all = params.select { |key,value| key.to_s.match(/^request\d+/) }

# 	puts reqs_all

# 	theEntry = Entry.find_by_id(id)

# 	theEntry.requests.delete_all

# 	reqs_all.each_with_index { |item, idx| 

# 		req = item[1]
# 		req.strip
# 		if req.length > 0
# 			theEntry.requests.create(request: req)
# 		end

# 		# item[1].strip
# 		# if item[1].length > 0
# 		# 	theEntry.requests.create(request: item)
# 		# end
# 	}

# 	redirect '/guide/' + params[:key] + '/editentries?apikey=1138&edited=' + id.to_s
# end

# post '/deleteguide/:id' do
# 	id = params[:id]
# 	guide = Guide.find(id)
# 	return status 404 if guide.nil?

# 	guide.delete
# 	status 202

# 	redirect '/guides/edit?apikey=1138&deleted=' + id.to_s
# end

# edit guide
# post '/editguide' do

# 	id = params[:guide]

# 	Guide.update(id, { :image => params[:image], :title => params[:title], :textLabel => params[:textLabel]})

# 	redirect '/guides/edit?apikey=1138&edited=' + id.to_s
# end

# post '/addguide' do

# 	newGuide = Guide.create(
# 		key: params[:guide_new],
# 		image: params[:image],
# 		title: params[:title],
# 		textLabel: params[:textLabel])
	
# 	redirect '/guides/edit?apikey=1138&added=' + newGuide.id.to_s
# end

# post '/guide/:key/deleteentry/:id' do
# 	id = params[:id]
# 	entry = Entry.find(id)
# 	return status 404 if entry.nil?

# 	entry.delete
# 	status 202

# 	redirect '/guide/' + params[:key] + '/editentries?apikey=1138&deleted=' + id.to_s

# end


# delete 'guide/entry/:id' do

# 	puts params[:_method]

# 	entry = Entry.find(params[:id])
# 	return status 404 if entry.nil?
# 	entry.delete
# 	status 202
# 	"Entry #{id} deleted."
# end


# post '/copyrequests/:from/:to' do
# 	fromEntryReqs = Request.where('"requests"."entry_id" = ?', params[:from])

# 	toEntry = Entry.find_by_id(params[:to])

# 	fromEntryReqs.each do |req|

# 		lastReq = Request.last
# 		nextid = lastReq.nil? ? 1 : lastReq.id + 1

# 		# req = Request.create(id: nextid, )
# 		toEntry.requests.create(request: req.request)

# 	end
	
# 	redirect '/guide/' + toEntry.guideKey + '/editentries?apikey=1138&edited=' + params[:to].to_s
# end

# post '/guide/:key/deleterequest/:id' do
# 	id = params[:id]
# 	request = Request.find(id)
# 	return status 404 if request.nil?

# 	request.delete
# 	status 202

# 	redirect '/guide/' + params[:key] + '/editentries?apikey=1138&deletedreq=' + id.to_s

# end



##############################################################################################################
# API version 3
get '/v3/guides' do
	content_type 'application/json'
	Guide.limit(5).to_json
end

get '/v3/guides/edit' do
	erb :edit_guide
end

# Get guide at index
get '/v3/guide/:id' do
	content_type 'application/json'

	guide = Guide.find_by_id(params[:id])

	return status 404 if guide.nil?

	guide.to_json
end

# Edit guide
post '/v3/guide/:id' do
	id = params[:id]

	Guide.update(id, { :image => params[:image], :title => params[:title], :textLabel => params[:textLabel]})

	redirect '/v3/guides/edit?apikey=1138&edited=' + id.to_s
end

# create guide
post '/v3/guide' do

	newGuide = Guide.create(
		key: params[:guide_new],
		image: params[:image],
		title: params[:title],
		textLabel: params[:textLabel])
	
	redirect '/v3/guides/edit?apikey=1138&added=' + newGuide.id.to_s
end
#end guide resources



#guide entries
get '/v3/guide/:key/entries/edit' do
	erb :db_form
end


# post '/v3/guide/:key/entry' do
# 	entry = nil

# 	name = params[:name]
# 	image = params[:image]

# 	nextid = Entry.last.id + 1

# 	puts nextid.to_s

# 	if !name.nil?
# 		entry = Entry.create(id: nextid, guideKey: params[:key], name: name, image: image, entrytype: params[:entrytype])

# 		if !image.nil?
# 			entry.image = image
# 		end

# 		redirect '/v3/guide/' + params[:key] + '/entries/edit?apikey=1138&added=' + entry.id.to_s + '&et=' + entry.entrytype.to_s
# 	else
# 		redirect '/v3/guide/' + params[:key] + '/entries/edit?apikey=1138&error=Error adding new entry.'
# 	end
# end
# post '/v3/guide/:key/entry/:entryid' do
# 	entryid = params[:entryid]

# 	Entry.update(entryid, { :image => params[:image], :name => params[:name], :entrytype => params[:entrytype], :bio => params[:bio], :location => params[:location], :include => params[:include] })

# 	reqs_all = params.select { |key,value| key.to_s.match(/^request\d+/) }

# 	puts reqs_all

# 	theEntry = Entry.find_by_id(id)

# 	theEntry.requests.delete_all

# 	reqs_all.each_with_index { |item, idx| 
# 		req = item[1]
# 		req.strip
# 		if req.length > 0
# 			theEntry.requests.create(request: req)
# 		end
# 	}

# 	redirect '/v3/guide/' + params[:key] + '/entries?apikey=1138&edited=' + id.to_s
# end



# v3 GetEntriesForGuide
get '/v3/guide/:key/entries' do
	content_type 'application/json'

	key = params[:key]

	if key == "refuge"
		sorted = guide_entries.sort_by &:id
	else
		sorted = guide_entries.select('id,"guideKey",name,image,entrytype,bio,location')
	end

	sorted.to_json(:include => :requests)
end

# get a single entry for "today" functionality (per guide)
get '/v3/guide/:key/entries/today' do
	content_type 'application/json'
	
	start_date = Date.new(2014, 7, 21)
	today = Date.today
	diff = (today-start_date).to_i
	idx = diff % guide_entries.length

	#production
	guide_entries[idx-1].to_json

end
#end guide entries


# entries/requests
# GET entry by Index
get '/v3/entry/:idx' do
	content_type 'application/json'

	entry = Entry.find_by_id(params[:idx])

	return entry.to_json(:include => :requests)
end

post '/v3/entry' do
	entry = nil

	guide = params[:guidekey]
	name = params[:name]
	image = params[:image]

	nextid = Entry.last.id + 1

	puts nextid.to_s

	if !name.nil?
		entry = Entry.create(id: nextid, guideKey: guide, name: name, image: image, entrytype: params[:entrytype])

		if !image.nil?
			entry.image = image
		end

		redirect '/v3/guide/' + guide + '/entries/edit?apikey=1138&added=' + entry.id.to_s + '&et=' + entry.entrytype.to_s
	else
		redirect '/v3/guide/' + guide + '/entries/edit?apikey=1138&error=Error adding new entry.'
	end
end

# Edit Entry by index
post '/v3/entry/:id' do
	id = params[:id]

	Entry.update(id, { :image => params[:image], :name => params[:name], :entrytype => params[:entrytype], :bio => params[:bio], :location => params[:location], :include => params[:include] })

	reqs_all = params.select { |key,value| key.to_s.match(/^request\d+/) }

	puts reqs_all

	theEntry = Entry.find_by_id(id)

	theEntry.requests.delete_all

	reqs_all.each_with_index { |item, idx| 
		req = item[1]
		req.strip
		if req.length > 0
			theEntry.requests.create(request: req)
		end
	}

	redirect '/v3/guide/' + params[:guidekey] + '/entries/edit?apikey=1138&edited=' + id.to_s
end
# GET requests for Entry
get '/v3/entry/:id/requests' do
	content_type 'application/json'

	theEntry = Entry.find_by_id(params[:id])
	requests = theEntry.requests || []

	requests.to_json
end
# DELETE entry
delete '/v3/entry/:id' do
	puts "*******************************************"
	puts params[:_method]
	puts "*******************************************"

	id = params[:id]

	entry = Entry.find(id)
	return status 404 if entry.nil?
	entry.delete
	status 200
	"Entry #{id} deleted."
end


# DELETE request
delete '/v3/request/:id' do
	id = params[:id]
	request = Request.find(id)
	return status 404 if request.nil?

	request.delete
	status 200

	# redirect '/v3/guide/' + params[:guidekey] + '/entries/edit?apikey=1138&deletedreq=' + id.to_s
end

# post '/copyrequests/:from/:to' do
post '/v3/requests/copy' do
	fromEntryReqs = Request.where('"requests"."entry_id" = ?', params[:from])

	toEntry = Entry.find_by_id(params[:to])

	fromEntryReqs.each do |req|

		lastReq = Request.last
		nextid = lastReq.nil? ? 1 : lastReq.id + 1

		# req = Request.create(id: nextid, )
		toEntry.requests.create(request: req.request)

	end
	
	status 200
	# redirect '/v3/guide/' + toEntry.guideKey + '/entries/edit?apikey=1138&edited=' + params[:to].to_s
end




#mission ops
get '/v3/ops/edit' do
	erb :edit_op_form
end
get '/v3/ops/report' do
	erb :ops_report
end
post '/v3/op' do
	puts "add " + params[:description]

	op = Op.create(
			category: params[:category].to_i,
			what: params[:what],
			when: params[:when],
			where: params[:where],
			description: params[:description])

	redirect '/v3/ops/edit?apikey=1138&added=' + op.id.to_s + '&cat=' + op.category.to_s
end

get '/v3/op/:id' do
	content_type 'application/json'

	op = Op.find_by_id(params[:id])

	return status 404 if op.nil?

	op.to_json
end

post '/v3/op/:id' do
	puts "edit " + params[:description]

	id = params[:id]
	Op.update(
		id, {
			:category => params[:category].to_i,
			:what => params[:what],
			:when => params[:when],
			:where => params[:where],
			:description => params[:description]
		})

	redirect '/v3/ops/edit?apikey=1138&edited=' + id.to_s
end

get '/v3/ops' do
	content_type 'application/json'
	
	cat = params[:category]

	if cat.nil? || cat.empty?
		mission_ops.to_json
	else
		mission_ops.where('ops.category = ?', cat.to_s).to_json
	end
end
#end mission ops








#################
# Static (image) handler

def send_static_file(path, &missing_file_block)
	file_path = File.join(File.dirname(__FILE__), 'public', path)

	File.exist?(file_path) ? send_file(file_path) : missing_file_block.call
end

get '/images/:filename' do
	send_static_file(request.path + '.png') {404}
end