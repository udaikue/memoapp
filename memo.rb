# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'
require 'date'
require 'pg'
require 'dotenv/load'

class Memo
  # DBに接続する
  def self.connect_db
    @connection = PG.connect(
      host: ENV['DB_HOST'],
      user: ENV['DB_USER'],
      password: ENV['DB_PASSWORD'],
      dbname: ENV['DB_NAME']
    )
  end

  # Memosテーブルを検索し更新時間順に並べる
  def self.all
    connect_db
    @connection.exec('SELECT id, title FROM Memos ORDER BY update_at DESC;')
  end

  # idが一致する行を検索する
  def self.fetch(id)
    connect_db
    @connection.exec("SELECT id, title, content FROM Memos WHERE id = #{id};")
  end

  # 入力されたデータを挿入する
  def self.insert(title, content)
    connect_db
    @connection.exec("INSERT INTO Memos (title, content, update_at) VALUES ('#{title}', '#{content}', current_timestamp);")
  end

  # idが一致する行を削除する
  def self.delete(id)
    connect_db
    @connection.exec("DELETE FROM Memos WHERE id = #{id};")
  end

  # DBとの接続を解除する
  def self.disconnect_db
    @connection.finish
  end
end

get '/' do
  redirect '/memos'
end

get '/memos/?' do
  begin
    @memos = Memo.all
  ensure
    Memo.disconnect_db
  end
  erb :memos
end

get '/new' do
  erb :new
end

post '/memos' do
  title = params[:memo_title]
  content = params[:memo_content]
  begin
    Memo.insert(title, content)
  ensure
    Memo.disconnect_db
  end
  redirect '/memos'
end

get '/memos/:id' do
  @id = params[:id]
  begin
    @memos = Memo.fetch(@id)
  ensure
    Memo.disconnect_db
  end
  erb :details
end

delete '/memos/:id/delete' do
  id = params[:id]
  begin
    Memo.delete(id)
  ensure
    Memo.disconnect_db
  end
  redirect '/memos'
end

get '/memos/:id/edit' do
  id = params[:id]
  begin
    memos = Memo.fetch(id)
    @title = memos.first['title']
    @content = memos.first['content']
  ensure
    Memo.disconnect_db
  end
  erb :edit
end

patch '/memos/:id/edit' do
  id = params[:id]
  title = params[:memo_title]
  content = params[:memo_content]

  begin
    Memo.delete(id)
    Memo.insert(title, content)
  ensure
    Memo.disconnect_db
  end
  redirect '/memos'
end
