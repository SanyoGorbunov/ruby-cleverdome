require 'ruby-cleverdome'
require 'ruby-cleverdome/types'

class WelcomeController < ApplicationController
	def index
		client = RubyCleverdome::Client.new()

		api_key = '=BKH^a-TMM$b9(bN(;(R!wQ2G&iwoQBycLP.Cq(z1Zfm/Ay[}K2b1%b[-mn=V5Bi|G^9wv5qXjz:FK&oy+/xJ$}v$>5-s#6{xVaeF6B:s%2%_^e][CxE3Sl!HI-fLuV:'
		user_id = 'TestSSO'
		session_id = client.auth(api_key, user_id)

=begin
content = ''
File.open('C:/Users/agorbunov/Downloads/Light-01.jpg', 'rb') { |file| content = file.read }

doc_guid = client.upload_file_binary(session_id, 8, 'Light-01.jpg', content)

client.add_document_tag(session_id, doc_guid, 'Tag Text 1')
client.add_document_tag(session_id, doc_guid, 'Tag Text 2')
client.add_document_tag(session_id, doc_guid, 'Tag Text 3')

hash_tags = client.get_document_tags(session_id, doc_guid)
render text: hash_tags.inspect
=end

		doc_guid = 'af5ba2a3-c3cd-11e3-bfc5-00155d09d70a'
		#list = client.get_security_groups(session_id, doc_guid)
		
		#render text: client.operations.inspect

		#render text: :get_group_permissions.to_s

		list = client.get_security_group_types(session_id)

		render text: list[1].name
	end
end
