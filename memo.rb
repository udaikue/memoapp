# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'
require 'date'

class Memo
  def initialize(new_json)
    @new_json = new_json
  end
  
  # jsonファイルを読み込む
  def self.read
    open('memos/memos.json') do |f|
      JSON.load(f)
    end
  end

  # jsonファイルを書き込む
  def self.write
    File.open('memos/memos.json', 'w') do |f|
      JSON.dump(@new_json, f)
    end
  end

  # 空のjsonデータをセットする
  def self.empty_add
    @new_json = { 'memos' => [] }
  end

  # 追加を反映させたjsonデータをセットする
  def self.fetch_add(id, title, content, time_str, old_json)
    add_memo = { id: id, title: title, content: content, update: time_str.to_i }
    ary_memo = old_json['memos'].push(add_memo)
    @new_json = { 'memos' => ary_memo }
  end

  # 削除を反映させたjsonデータをセットする
  def self.fetch_delete(id, old_json)
    del_ary = old_json['memos'].delete_if { |a| a['id'] == id.to_i }
    @new_json = { 'memos' => del_ary }
  end
end

get '/' do
  redirect '/memos'
end

get '/memos/?' do
  # 保存用のjsonファイルが存在しなければファイルを作成する
  unless File.exist?('memos/memos.json')
    Memo.empty_add
    Memo.write
  end
  @json_data = Memo.read
  erb :memos
end

get '/new' do
  erb :new
end

post '/memos' do
  old_json = Memo.read
  id = SecureRandom.random_number(999999999)
  title = params[:memo_title]
  content = params[:memo_content]
  time_str = Time.now.strftime('%Y%m%d%H%M%S')
  Memo.fetch_add(id, title, content, time_str, old_json)
  Memo.write

  redirect '/memos'
end

get '/memos/:id' do
  @id = params[:id].delete(':')
  @json_data = Memo.read
  erb :details
end

delete '/memos/:id/delete' do
  id = params[:id].delete(':')
  old_json = Memo.read
  Memo.fetch_delete(id, old_json)
  Memo.write

  redirect '/memos'
end

get '/memos/:id/edit' do
  id = params[:id].delete(':')
  json_data = Memo.read
  json_data['memos'].each do |js|
    if js['id'] == id.to_i
      @title = js['title']
      @content = js['content']
    end
  end
  erb :edit
end

patch '/memos/:id/edit' do
  id = params[:id].delete(':')
  old_json = Memo.read
  Memo.fetch_delete(id, old_json)
  Memo.write

  old_json = Memo.read
  id = SecureRandom.random_number(999999999)
  title = params[:memo_title]
  content = params[:memo_content]
  time_str = Time.now.strftime('%Y%m%d%H%M%S')
  Memo.fetch_add(id, title, content, time_str, old_json)
  Memo.write

  redirect '/memos'
end
