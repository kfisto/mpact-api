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
  'mpact api'
end

get '/guides' do
	content_type 'application/json'
	Guide.limit(5).to_json
end

get '/guides/edit' do
	erb :edit_guide
end


helpers do
	def guides_all
		@guides_all ||= Guide.order('key ASC') || halt(404)
	end

	def guide_entries_all
		@guide_entries_all ||= Entry.where('"entries"."guideKey" = ?', params[:key]).order('entrytype ASC', 'name ASC').select('id,"guideKey",name,image,bio,entrytype,location') || halt(404)
	end

	def guide_entries
		@guide_entries ||= Entry.order('entrytype ASC, name ASC').where('"entries"."guideKey" = ?', params[:key]) || halt(404)
		# @guide_entries ||= Entry.order('entrytype ASC, name ASC').where('"entries"."guideKey" = ? AND "entries"."image" != ?', params[:key], "none") || halt(404)
		# @guide_entries ||= Entry.order('entrytype ASC, name ASC').where('"entries"."guideKey" = ? AND "entries"."image" != ? AND coalesce("entries"."image", \'\') != \'\'', params[:key], "none") || halt(404)
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
			sorted = guide_entries_all.select('id,"guideKey",name,image,entrytype')
		else 
			puts "return subset"
			sorted = guide_entries.select('id,"guideKey",name,image,entrytype')
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
get '/ops/add' do
	erb :add_op_form
end
get '/ops/edit' do
	erb :edit_op_form
end
post '/ops/add' do
	puts "add " + params[:description]

	op = Op.create(
			category: params[:category].to_i,
			what: params[:what],
			when: params[:when],
			where: params[:where],
			description: params[:description])

	redirect '/ops/add?apikey=1138&added=' + op.id.to_s + '&cat=' + op.category.to_s
end
post '/ops/edit' do
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

	redirect '/ops/edit?apikey=1138&edited=' + id.to_s
end
get '/ops/:cat' do
	content_type 'application/json'
	mission_ops.where('ops.category = ?', params[:cat].to_s).to_json
end
get '/ops' do
	content_type 'application/json'
	mission_ops.to_json
end
#end mission ops

get '/guide/:key/addentry' do
	erb :add_form
end

get '/entry/:idx' do
	content_type 'application/json'

	entry = Entry.find_by_id(params[:idx])
	
	return entry.to_json(:include => :requests)

	# retval["requests"] = reqs.to_json


	# return retval
end

post '/guide/:key/entry' do

	entry = nil

	name = params[:name]
	image = params[:image]
	# filename = params[:datafile] if !params[:datafile].nil?
	# content = params[:dfcontent]

	# nextid = Entry.last.id + 1

	# puts nextid.to_s

	if !name.nil?
		# puts "do stuff"
		entry = Entry.create(guideKey: params[:key], name: name, image: image, entrytype: params[:entrytype])

		if !image.nil?
			entry.image = image
		end

		redirect '/guide/' + params[:key] + '/addentry?apikey=1138&added=' + entry.id.to_s + '&et=' + entry.entrytype.to_s
	else
		redirect '/guide/' + params[:key] + '/addentry?apikey=1138&error=Error adding new entry.'
	end

end

get '/guide/:key/editentries' do
	erb :db_form
end

post '/guide/:key/editentry' do

	id = params[:entry]

	Entry.update(id, { :image => params[:image], :name => params[:name], :entrytype => params[:entrytype], :bio => params[:bio], :location => params[:location]})

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

		# item[1].strip
		# if item[1].length > 0
		# 	theEntry.requests.create(request: item)
		# end
	}

	redirect '/guide/' + params[:key] + '/editentries?apikey=1138&edited=' + id.to_s
end

post '/deleteguide/:id' do
	id = params[:id]
	guide = Guide.find(id)
	return status 404 if guide.nil?

	guide.delete
	status 202

	redirect '/guides/edit?apikey=1138&deleted=' + id.to_s
end

# edit guide
post '/editguide/:id' do

	id = params[:guide]

	Guide.update(id, { :image => params[:image], :title => params[:title], :textLabel => params[:textLabel]})

	redirect '/guide/edit?apikey=1138&edited=' + id.to_s
end

post '/addguide' do

	newGuide = Guide.create(
		key: params[:guide_new],
		image: params[:image],
		title: params[:title],
		textLabel: params[:textLabel])
	
	redirect '/guides/edit?apikey=1138&added=' + newGuide.id.to_s
end

post '/guide/:key/deleteentry/:id' do
	id = params[:id]
	entry = Entry.find(id)
	return status 404 if entry.nil?

	entry.delete
	status 202

	redirect '/guide/' + params[:key] + '/editentries?apikey=1138&deleted=' + id.to_s

end


delete 'guide/entry/:id' do

	puts params[:_method]

	entry = Entry.find(params[:id])
	return status 404 if entry.nil?
	entry.delete
	status 202
	"Entry #{id} deleted."
end




#################
# Static (image) handler

def send_static_file(path, &missing_file_block)
	file_path = File.join(File.dirname(__FILE__), 'public', path)

	File.exist?(file_path) ? send_file(file_path) : missing_file_block.call
end

get '/images/:filename' do
	send_static_file(request.path + '.png') {404}
end