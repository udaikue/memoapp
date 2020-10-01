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

  # ブロックを利用してDBに接続・接続解除する
  def self.db(&block)
    connect_db
    yield block
    disconnect_db
  end

  # Memosテーブルを検索し更新時間順に並べる
  def self.all
    @connection.exec('SELECT id, title FROM Memos ORDER BY update_at DESC;')
  end

  # idが一致する行を検索する
  def self.fetch(id)
    @connection.exec("SELECT id, title, content FROM Memos WHERE id = #{id};")
  end

  # 新しいデータを追加する
  def self.insert(title, content)
    @connection.exec("INSERT INTO Memos (title, content, update_at) VALUES ('#{title}', '#{content}', current_timestamp);")
  end

  # データを更新する
  def self.update(id, title, content)
    @connection.exec("UPDATE Memos SET title = '#{title}', content = '#{content}', update_at = current_timestamp WHERE id = #{id};")
  end

  # idが一致する行を削除する
  def self.delete(id)
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
  Memo.db do
    @memos = Memo.all
  end
  erb :memos
end

get '/new' do
  erb :new
end

post '/memos' do
  title = params[:memo_title]
  content = params[:memo_content]
  Memo.db do
    Memo.insert(title, content)
  end
  redirect '/memos'
end

get '/memos/:id' do
  @id = params[:id]
  Memo.db do
    @memos = Memo.fetch(@id)
  end
  erb :details
end

delete '/memos/:id/delete' do
  id = params[:id]
  Memo.db do
    Memo.delete(id)
  end
  redirect '/memos'
end

get '/memos/:id/edit' do
  id = params[:id]
  Memo.db do
    memos = Memo.fetch(id)
    @title = memos.first['title']
    @content = memos.first['content']
  end
  erb :edit
end

patch '/memos/:id/edit' do
  id = params[:id]
  title = params[:memo_title]
  content = params[:memo_content]
  Memo.db do
    Memo.update(id, title, content)
  end
  redirect '/memos'
end
